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
# * If you need more than one constraint per parameter, enclose these constraints within an array.
# * Depending on the type of method you're constructing, there will be additional constraints both implied and explictly allowed:
#   * named methods do not require any items by default, they must be specified as required.
#   * ordered methods require everything by default, they must be specified as optional.
#
module MethLab

    VERSION = "0.0.5"

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
    # used to perform our standard checks.
    def self.check_type(value_sig, value, key)
        case value_sig
        when Array
            value_sig.flatten.each do |vs|
                ret = check_type(vs, value, key)
                return ret unless ret.nil?
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
   
    # internal, do not use directly.
    #
    # used to check the arity of array (ordered) method calls.
    def self.validate_array_params(signature, args)
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
                return ret unless ret.nil?
            end
        end

        return args
    end

    # internal, do not use directly.
    #
    # Used to check the sanity of parameterized (named) method calls.
    def self.validate_params(signature, *args)
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
                return ret unless ret.nil?
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
            send(:instance_variable_set, "@" + method_name.to_s, value)
        end

        self.send(:define_method, method_name) do
            instance_variable_get("@" + method_name.to_s)
        end
    end

    if $METHLAB_AUTOINTEGRATE
        integrate
    end
end
