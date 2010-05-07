begin
    require 'rubygems'
    gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

MethLab.integrate

class DefaultClass
    def_named(:named, 
              :foo => [String, {:default => "foo"}, :required], 
              :bar => [String, {:default => "bar"}] 
             ) do |params|
                 params
             end
    
    def_ordered(:ordered, 
                [String, {:default => "foo"}, :required], 
                [String, {:default => "bar"}]
               ) do |params|
                   params
               end

    def_attr :ml_attr, [String, {:default => "foo"}]
end

class TestDefaults < Test::Unit::TestCase
    def setup
        @default = DefaultClass.new
    end

    def test_01_named
        assert(@default.respond_to?(:named))

        assert_equal(@default.named, {:foo => "foo", :bar => "bar"})
        assert_equal(@default.named(:foo => "fixme"), {:foo => "fixme", :bar => "bar"})
        assert_equal(@default.named(:foo => "fixme", :bar => "woot"), {:foo => "fixme", :bar => "woot"})
    end

    def test_02_ordered
        assert(@default.respond_to?(:ordered))

        assert_equal(@default.ordered, ["foo", "bar"])
        assert_equal(@default.ordered("fixme"), ["fixme", "bar"])
        assert_equal(@default.ordered("fixme", "woot"), ["fixme", "woot"])
    end

    def test_03_attr
        assert(@default.respond_to?(:ml_attr))

        assert_equal(@default.ml_attr, "foo")
        @default.ml_attr = "bar"
        assert_equal(@default.ml_attr, "bar")
    end
end
