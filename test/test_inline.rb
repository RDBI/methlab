begin
  require 'rubygems'
  gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

class InlineTest
  extend MethLab

  inline(:foo) { nil }
  inline(:bar, :baz, :quux) { 1 }

  attr_threaded_accessor(:one, :two)
end

class TestInline < Test::Unit::TestCase
  def test_01_inline_works
    it = InlineTest.new

    assert_equal(nil, it.foo)

    [:bar, :baz, :quux].each do |meth|
      assert_equal(1, it.send(meth))
    end
  end

  def test_02_attr_threaded_accessor
    it = InlineTest.new

    it.one = 1
    it.two = 2

    assert_equal(it.one, 1)
    assert_equal(it.two, 2)
    assert_equal(Thread.current[:one], 1)
    assert_equal(Thread.current[:two], 2)
  end
end
