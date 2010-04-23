begin
    require 'rubygems'
    gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

class CheckClass
    extend MethLab

    named_method(:named, :stuff => String, :stuff2 => [ /pee/, :required ], :stuff3 => :required) do |params| 
        [:stuff, :stuff2, :stuff3].collect { |x| params[x] }
    end

    checked_method(:sequential, String, [Integer, :optional]) do |params|
        params
    end
end

module CheckModule
    extend MethLab

    named_method(:named, :stuff => String, :stuff2 => [ /pee/, :required ], :stuff3 => :required) do |params| 
        [:stuff, :stuff2, :stuff3].collect { |x| params[x] }
    end

    checked_method(:sequential, String, [Integer, :optional]) do |params|
        params
    end
end

class TestChecks < Test::Unit::TestCase
    def setup
        @check = CheckClass.new
    end

    def test_01_named
        assert(@check.respond_to?(:named))
        
        assert_raises(ArgumentError.new("value of argument 'stuff' is an invalid type. Requires 'String'")) do
            @check.named(:stuff => 1, :stuff2 => "pee", :stuff3 => 1)
        end
        
        assert_raises(ArgumentError.new("value of argument 'stuff2' does not match this regexp: '(?-mix:pee)'")) do
            @check.named(:stuff => "foo", :stuff2 => "bar", :stuff3 => 1)
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2' were not found but are required by the prototype")) do
            @check.named(:stuff => "foo", :stuff3 => 1)
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2, stuff3' were not found but are required by the prototype")) do
            @check.named(:stuff => "foo")
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2' were not found but are required by the prototype")) do
            @check.named(:stuff => "foo", :stuff3 => nil)
        end

        @check.named(:stuff => "foo", :stuff2 => "poopee", :stuff3 => 1)
    end

    def test_02_checked
        assert(@check.respond_to?(:sequential))

        assert_raises(ArgumentError.new("value of argument '0' is an invalid type. Requires 'String'")) do
            @check.sequential(nil)
        end
        
        assert_raises(ArgumentError.new("value of argument '1' is an invalid type. Requires 'Integer'")) do
            @check.sequential("foo", "bar")
        end
        
        assert_raises(ArgumentError.new("value of argument '1' is an invalid type. Requires 'Integer'")) do
            @check.sequential("foo", nil)
        end

        assert_raises(ArgumentError.new("too many arguments (3 for 2)")) do
            @check.sequential("foo", 1, nil)
        end

        @check.sequential("foo")
        @check.sequential("foo", 1)
    end
end