begin
    require 'rubygems'
    gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

class CheckedClass
    extend MethLab

    def_named(:named, :stuff => String, :stuff2 => [ /pee/, :required ], :stuff3 => :required) do |params| 
        [:stuff, :stuff2, :stuff3].collect { |x| params[x] }
    end

    def_ordered(:sequential, String, [Integer, :optional]) do |params|
        params
    end

    def_ordered(:ranged, (0..9)) do |params|
        params
    end
end

# FIXME module tests

class TestChecks < Test::Unit::TestCase
    def setup
        @checked = CheckedClass.new
    end

    def test_01_named
        assert(@checked.respond_to?(:named))
        
        assert_raises(ArgumentError.new("value of argument 'stuff' is an invalid type. Requires 'String'")) do
            @checked.named(:stuff => 1, :stuff2 => "pee", :stuff3 => 1)
        end
        
        assert_raises(ArgumentError.new("value of argument 'stuff2' does not match this regexp: '(?-mix:pee)'")) do
            @checked.named(:stuff => "foo", :stuff2 => "bar", :stuff3 => 1)
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2' were not found but are required by the prototype")) do
            @checked.named(:stuff => "foo", :stuff3 => 1)
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2, stuff3' were not found but are required by the prototype")) do
            @checked.named(:stuff => "foo")
        end

        assert_raises(ArgumentError.new("argument(s) 'stuff2' were not found but are required by the prototype")) do
            @checked.named(:stuff => "foo", :stuff3 => nil)
        end

        assert_equal(
            @checked.named(:stuff => "foo", :stuff2 => "poopee", :stuff3 => 1), 
            ["foo", "poopee", 1]
        )
    end

    def test_02_checked
        assert(@checked.respond_to?(:sequential))

        assert_raises(ArgumentError.new("value of argument '0' is an invalid type. Requires 'String'")) do
            @checked.sequential(nil)
        end
        
        assert_raises(ArgumentError.new("value of argument '1' is an invalid type. Requires 'Integer'")) do
            @checked.sequential("foo", "bar")
        end
        
        assert_raises(ArgumentError.new("value of argument '1' is an invalid type. Requires 'Integer'")) do
            @checked.sequential("foo", nil)
        end

        assert_raises(ArgumentError.new("too many arguments (3 for 2)")) do
            @checked.sequential("foo", 1, nil)
        end

        assert_raises(ArgumentError.new("not enough arguments (0 for minimum 1)")) do
            @checked.sequential()
        end

        assert_equal(@checked.sequential("foo"), ["foo"])
        assert_equal(@checked.sequential("foo", 1), ["foo", 1])
    end

    def test_03_ranges
        assert(@checked.respond_to?(:ranged))

        assert_raises(ArgumentError.new("value of argument '0' does not match range '0..9'")) do
            @checked.ranged(-1)
        end

        assert_raises(ArgumentError.new("value of argument '0' does not match range '0..9'")) do
            @checked.ranged("foo")
        end

        assert_raises(ArgumentError.new("value of argument '0' does not match range '0..9'")) do
            @checked.ranged(10)
        end

        assert_equal(@checked.ranged(5), [5])
    end
end
