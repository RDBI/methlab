module MethLab
    def self.integrate
        ::Object.send(:include, MethLab)
    end

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
        when Regexp
            unless value.to_s =~ value_sig
                return ArgumentError.new("value of argument '#{key}' does not match this regexp: '#{value_sig.to_s}'")
            end
        end

        return nil
    end
    
    # FIXME 'not enough arguments'
    def self.validate_array_params(signature, args)
        unless args.kind_of?(Array)
            return ArgumentError.new("this method takes ordered arguments")
        end

        if args.length > signature.length
            return ArgumentError.new("too many arguments (#{args.length} for #{signature.length})")
        end

        args.each_with_index do |value, key|
            unless signature[key]
                return ArgumentError.new("argument #{key} does not exist in prototype")
            end

            if !signature[key].nil?
                ret = check_type(signature[key], value, key)
                return ret unless ret.nil?
            end
        end

        return args
    end

    def self.validate_params(signature, *args)
        args = args[0]
        
        unless args.kind_of?(Hash)
            return ArgumentError.new("this method takes a hash")
        end

        args.each do |key, value|
            unless signature.has_key?(key)
                return ArgumentError.new("argument '#{key}' does not exist in prototype")
            end

            if !signature[key].nil?
                ret = check_type(signature[key], value, key)
                return ret unless ret.nil?
            end
        end

        keys = signature.each_key.select { |key| [signature[key]].flatten.include?(:required) and !args.has_key?(key) }

        if keys.length > 0
            return ArgumentError.new("argument(s) '#{keys.join(", ")}' were not found but are required by the prototype")
        end

        return args
    end

    # FIXME build options that these leverage to define
    def checked_method(method_name, *args, &block)
        signature = args

        op_index = signature.index(:optional)

        if op_index and signature.reject { |x| x == :optional }.length != op_index
            raise ArgumentError, ":optional parameters must be at the end"
        end
       
        self.send(:define_method, method_name) do |*args| 
            params = MethLab.validate_array_params(signature, args)
            raise params if params.kind_of?(Exception)
            block.call(params)
        end

        method_name
    end

    def named_method(method_name, *args, &block)
        signature = args[0]

        self.send(:define_method, method_name) do |*args| 
            params = MethLab.validate_params(signature, *args)
            raise params if params.kind_of?(Exception)
            block.call(params)
        end

        method_name
    end

    if $METHLAB_AUTOINTEGRATE
        integrate
    end
end
