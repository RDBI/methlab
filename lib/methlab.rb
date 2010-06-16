#
# MethLab - a method toolkit for ruby.
#
# MethLab is next to useless without integrating it into your classes. You can
# do this several ways:
#
# * 'extend MethLab' in your class definitions before calling any of MethLab's helpers.
# * 'MethLab.integrate' anywhere. This will inject it into ::main and ::Module.
# * set $METHLAB_AUTOINTEGRATE to true before requiring methlab. This calls 'MethLab.integrate' automatically.
#
# Please see MethLab#build_ordered and MethLab#build_named for method creation
# syntax. Note that MethLab#def_named and MethLab#def_ordered will create named
# methods in your class for you, but they use the build methods underneath the
# hood.
#
# Here's an example:
# 
#   class Awesome
#     def_ordered(:foo, String, [Integer, :optional]) do |params|
#       str, int = params
#       puts "I received #{str} as a String and #{int} as an Integer!"
#     end
# 
#     def_named(:bar, :foo => String, :bar => [Integer, :required]) do |params|
#       puts "I received #{params[:foo]} as a String and #{params[:bar]} as an Integer!"
#     end
#
#     def some_method(*args) # a hash
#       params = MethLab.validate_params(:foo => String, :bar => [Integer, :required])
#       raise params if params.kind_of? Exception
#
#       puts "I received #{params[:foo]} as a String and #{params[:bar]} as an Integer!"
#     end
#   end
# 
# Which yields these opportunities:
# 
#   a = Awesome.new
#   a.foo(1, "str") # raises
#   a.foo("str", 1) # prints the message
#   a.foo("str")    # prints the message with nil as the integer
# 
#   a.bar(:foo => 1, :bar => "str") # raises
#   a.bar(:foo => "str")            # raises (:bar is required)
#   a.bar(:bar => 1)                # prints message, with nil string
#   a.bar(:foo => "str", :bar => 1) # prints message
# 
#   a.some_method(:foo => "str", :bar => 1) # prints message
#
# Using it is quite simple. Just remember a few things:
#
# * A class will always be compared with Object#kind_of? against the object. 
# * An object implies certain semantics. Right now, we support direct checking against multiple objects:
#   * Regexp's will convert the value to a string and compare them with String#=~
#   * Ranges will use Range#include? to determine if the object occurs within the range.
#   * A proc will allow you to do a custom check, taking one argument. Raises happen as such:
#     * Returning false/nil will raise a generic error.
#     * Returning a new exception object (e.g., ArgumentError.new) will raise your error as close to the call point as possible.
#     * Raising yourself will raise in the validation routine, which will probably be confusing. Please use the above method.
#   * A symbol is a pragma that implies a constraint -- see below.
#   * A hash is a way of specifying a pragma (or check) with a parameter:
#     * :respond_to calls Object#respond_to? on the method named as the value (a symbol) 
#     * :default specifies a default argument. This is still checked, so get it right!
# * If you need more than one constraint per parameter, enclose these constraints within an array.
# * Depending on the type of method you're constructing, there will be additional constraints both implied and explictly allowed:
#   * named methods do not require any items by default, they must be specified as required.
#   * ordered methods require everything by default, they must be specified as optional.
#
module MethLab

    VERSION = "0.0.9"

    # Integrates MethLab into all namespaces. It does this by patching itself
    # into ::main and Module.
    #
    # You may also accomplish this automatically by setting
    # $METHLAB_AUTOINTEGRATE before you require it.
    def self.integrate
        eval("self", TOPLEVEL_BINDING).send(:include, self)
        ::Module.send(:include, self)
    end

    # internal, please do not use directly.
    #
    # used to set defaults on parameters that require one
    def self.set_defaults(signature, params, kind=:array)
        params = params[0] if kind == :hash

        signature.each_with_index do |value, index|
            case kind
            when :array
                if value.kind_of?(Array)
                    if hashes = value.find_all { |x| x.kind_of?(Hash) } and !hashes.empty?
                        hashes.each do |hash|
                            if hash.has_key?(:default) and (params.length - 1) < index
                                params[index] = hash[:default]
                            end
                        end
                    end
                end
            when :hash
                if value[1].kind_of?(Array)
                    if hashes = value[1].find_all { |x| x.kind_of?(Hash) } and !hashes.empty?
                        hashes.each do |hash|
                            if hash.has_key?(:default) and !params.has_key?(value[0]) 
                                params[value[0]] = hash[:default]
                            end
                        end
                    end
                end
            end
        end
    end
    
    # internal, please do not use directly.
    #
    # used to perform our standard checks that are supplied via hash.
    def self.check_hash_types(value_key, value_value, value, key)
        case value_key
        when :respond_to
            unless value.respond_to?(value_value)
                return ArgumentError.new("value of argument '#{key}' does not respond to '#{value_value}'")
            end
        end
        return nil
    end

    # internal, please do not use directly.
    #
    # used to perform our standard checks.
    def self.check_type(value_sig, value, key)
        case value_sig
        when Array
            value_sig.flatten.each do |vs|
                ret = check_type(vs, value, key)
                return ret if ret
            end
        when Hash
            value_sig.each do |value_key, value_value| # GUH
                ret = check_hash_types(value_key, value_value, value, key)
                return ret if ret
            end
        when Class 
            unless value.kind_of?(value_sig)
                return ArgumentError.new("value of argument '#{key}' is an invalid type. Requires '#{value_sig}'")
            end
        when Proc
            ret = value_sig.call(value)

            if ret.kind_of?(Exception)
                return ret
            elsif !ret
                return ArgumentError.new("value of argument '#{key}' does not pass custom validation.")
            else
                return nil
            end
        when Regexp
            unless value.to_s =~ value_sig
                return ArgumentError.new("value of argument '#{key}' does not match this regexp: '#{value_sig.to_s}'")
            end
        when Range
            unless value_sig.include?(value)
                return ArgumentError.new("value of argument '#{key}' does not match range '#{value_sig.inspect}'")
            end
        end

        return nil
    end
   
    # This method takes the same signature as Methlab#build_ordered, and the
    # arguments you wish to validate. It will process everything just like you
    # built a method to handle this, but just with the arguments you prefer.
    #
    # This method will return either an Exception or an Array; if you receive
    # an exception, this means that parsing errors occured, you may raise this
    # exception from the point of your method if you wish.
    def self.validate_array_params(signature, args)
        args = [] unless args

        MethLab.set_defaults(signature, args, :array)

        unless args.kind_of?(Array)
            return ArgumentError.new("this method takes ordered arguments")
        end

        if args.length > signature.length
            return ArgumentError.new("too many arguments (#{args.length} for #{signature.length})")
        end

        opt_index = signature.find_index { |x| [x].flatten.include?(:optional) } || 0
        
        if args.length < opt_index
            return ArgumentError.new("not enough arguments (#{args.length} for minimum #{opt_index})")
        end

        args.each_with_index do |value, key|
            unless signature[key]
                return ArgumentError.new("argument #{key} does not exist in prototype")
            end

            if signature[key]
                ret = check_type(signature[key], value, key)
                return ret if ret
            end
        end

        return args
    end

    # This method takes the same signature as Methlab#build_named, and the
    # arguments you wish to validate. It will process everything just like you
    # built a method to handle this, but just with the arguments you prefer.
    #
    # This method will return either an Exception or an Array; if you receive
    # an exception, this means that parsing errors occured, you may raise this
    # exception from the point of your method if you wish.
    def self.validate_params(signature, *args)
        args = [{}] if args.empty?
        MethLab.set_defaults(signature, args, :hash)
        args = args[0]
        
        unless args.kind_of?(Hash)
            return ArgumentError.new("this method takes a hash")
        end

        args.each do |key, value|
            unless signature.has_key?(key)
                return ArgumentError.new("argument '#{key}' does not exist in prototype")
            end

            if signature[key]
                ret = check_type(signature[key], value, key)
                return ret if ret
            end
        end

        keys = signature.each_key.select { |key| [signature[key]].flatten.include?(:required) and !args.has_key?(key) }

        if keys.length > 0
            return ArgumentError.new("argument(s) '#{keys.sort_by { |x| x.to_s }.join(", ")}' were not found but are required by the prototype")
        end

        return args
    end

    # Builds an unbound method as a proc with ordered parameters.
    #
    # Example:
    #
    #   my_proc = build_ordered(String, [Integer, :optional]) do |params|
    #     str, int = params
    #     puts "I received #{str} as a String and #{int} as an Integer!"
    #   end
    #
    #   my_proc.call("foo", 1)
    #  
    # As explained above, an array to combine multiple parameters at a position
    # may be used to flag it with additional data. At this time, these
    # parameters are supported:
    #
    # * :optional - is not required as a part of the argument list.
    #
    def build_ordered(*args, &block)
        signature = args

        op_index = signature.index(:optional)

        if op_index and signature.reject { |x| x == :optional }.length != op_index
            raise ArgumentError, ":optional parameters must be at the end"
        end
        
        proc do |*args| 
            params = MethLab.validate_array_params(signature, args)
            raise params if params.kind_of?(Exception)
            block.call(params)
        end
    end

    # similar to MethLab#build_ordered, but takes a method name as the first
    # argument that binds to a method with the same name in the current class
    # or module. Currently cannot be a class method.
    def def_ordered(method_name, *args, &block)
        self.send(:define_method, method_name, &build_ordered(*args, &block)) 
        return method_name
    end

    # Builds an unbound method as a proc with named (Hash) parameters.
    #
    # Example:
    #
    #   my_proc = build_named(:foo => String, :bar => [Integer, :required]) do |params|
    #     puts "I received #{params[:foo]} as a String and #{params[:bar]} as an Integer!"
    #   end
    #
    #   my_proc.call(:foo => "foo", :bar => 1)
    #  
    # As explained above, an array to combine multiple parameters at a position
    # may be used to flag it with additional data. At this time, these
    # parameters are supported:
    #
    # * :required - this field is a required argument (parameters are default optional)
    #
    def build_named(*args, &block)
        signature = args[0]

        proc do |*args|
            params = MethLab.validate_params(signature, *args)
            raise params if params.kind_of?(Exception)
            block.call(params)
        end
    end

    # similar to MethLab#build_named, but takes a method name as the first
    # argument that binds to a method with the same name in the current class
    # or module. Currently cannot be a class method.
    def def_named(method_name, *args, &block)
        self.send(:define_method, method_name, &build_named(*args, &block))
        return method_name
    end

    # Similar to MethLab#build_ordered, but builds attributes similar to
    # attr_accessor. Takes a single parameter which is the constraint
    # specification.
    #
    # Example:
    #
    #   def_attr :set_me, String
    #
    #   # later on..
    #   myobj.set_me = 0 # raises
    #   myobj.set_me = "String" # valid
    #
    def def_attr(method_name, arg)

        self.send(:define_method, (method_name.to_s + "=").to_sym) do |value| 
            signature = [arg]
            params = MethLab.validate_array_params(signature, [value])
            raise params if params.kind_of?(Exception)
            send(:instance_variable_set, "@" + method_name.to_s, params[0])
        end

        self.send(:define_method, method_name) do
            unless self.instance_variables.select { |x| x == "@#{method_name}" || x == "@#{method_name}".to_sym }[0]
                args = []
                MethLab.set_defaults([arg], args, :array)
                send(:instance_variable_set, "@#{method_name}", args[0])
            end

            instance_variable_get("@#{method_name}")
        end
    end

    #
    # inline is useful to spec out several methods at once to yield similar values.
    #
    # Usage:
    # 
    #   class Foo
    #     inline(:one, :two, :three) { 1 }
    #   end
    #   
    #   f = Foo.new
    #   f.one   # => 1
    #   f.two   # => 1
    #   f.three # => 1
    #
    def inline(*method_names, &block)
        method_names.each do |meth|
            self.send(:define_method, meth, block)
        end
    end

    #
    # attr_threaded_accessor creates thread-local accessors via
    # +Thread.current+. As a result, while these are accessed in your class,
    # they live in a flat namespace, and must be used with caution.
    #
    # Usage:
    #
    #   class Foo
    #     attr_threaded_accessor(:one, :two)
    #
    #     def bar
    #       self.one = 1
    #       self.two = 2
    #     end
    #   end
    #
    #   f = Foo.new
    #   f.one # 1
    #   f.two # 2
    #
    #   Thread.current[:one] # => 1
    #   Thread.current[:two] # => 2
    #
    def attr_threaded_accessor(*method_names)
        method_names.each do |meth|
            self.send(:define_method, meth, proc { Thread.current[meth] })
            meth2 = meth.to_s.gsub(/$/, '=').to_sym
            self.send(:define_method, meth2, proc { |x| Thread.current[meth] = x })
        end
    end

    if $METHLAB_AUTOINTEGRATE
        integrate
    end
end
