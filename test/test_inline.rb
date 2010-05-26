begin
    require 'rubygems'
    gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

class InlineTest
    inline(:foo) { nil }
    inline(:bar, :baz, :quux) { 1 }
end

class TestInline < Test::Unit::TestCase
    def test_01_inline_works
        it = InlineTest.new

        assert_equal(nil, it.foo)

        [:bar, :baz, :quux].each do |meth|
            assert_equal(1, it.send(meth))
        end
    end
end
