YARD::Parser::SourceParser.parser_type = :ruby18

module MethLab
  module YARD
    include ::YARD::CodeObjects

    class DefOrderedHandler < ::YARD::Handlers::Ruby::Legacy::Base
    end

    class DefNamedHandler < ::YARD::Handlers::Ruby::Legacy::Base
    end
    
    class DefAttrHandler < ::YARD::Handlers::Ruby::Legacy::Base
    end

    class InlineHandler < ::YARD::Handlers::Ruby::Legacy::MethodHandler
      MATCHER = %r!\Ainline(?:\(|\s+)!
      SYM_MATCHER = %r!(?:(:[\w\!?]+)\n?,?)! 
      handles MATCHER 

      def process
        objnames = statement.tokens.to_s.scan(SYM_MATCHER).flatten
        objnames.each do |name| 
          name = name.sub!(/:/, '')

          obj = register MethodObject.new(namespace, name, scope) do |o| 
            o.visibility = visibility 
            o.source = statement
            o.explicit = true
            #o.parameters = args
          end
          parse_block :owner => obj
        end
      end
    end

    class AttrThreadedAccessorHandler < InlineHandler
      MATCHER = %r!\Aattr_threaded_accessor(?:\(|\s+)!
      SYM_MATCHER = %r!(?:(:[\w\!?]+)\n?,?)! 
      handles MATCHER 
    end
  end
end
