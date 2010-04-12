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

    def self.validate_params(signature, *args)
        args = args[0] if args.kind_of?(Array)
        
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
            return ArgumentError.new("arguments '#{keys.join(", ")}' were not found but are required by the prototype")
        end

        return args
    end

    def named_method(method_name, *args, &block)
        signature = args[0]

        obj = self.kind_of?(Module) ? self : self.class

        obj.send(:define_method, method_name) do |*args| 
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

if __FILE__ == $0
    MethLab.integrate
    named_method(:foo, :stuff => String, :stuff2 => [ /pee/, :required ]) { |params| "#{params[:stuff]} - fart - #{params[:stuff2].inspect}" }

    p foo(:stuff => "stuff", :stuff2 => "pee")
end
