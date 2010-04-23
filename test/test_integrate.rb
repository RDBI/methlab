begin
    require 'rubygems'
    gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

class TestIntegrate < Test::Unit::TestCase
    def test_01_integration
        MethLab.integrate
        assert(Object.instance_methods.include?("named_method"))
        assert(Object.instance_methods.include?("checked_method"))
    end
end
