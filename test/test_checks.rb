begin
  require 'rubygems'
  gem 'test-unit'
rescue LoadError
end

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'methlab'

MethLab.integrate

class CheckedClass
  def_named(:named, :stuff => String, :stuff2 => [ /pee/, :required ], :stuff3 => :required) do |params| 
    [:stuff, :stuff2, :stuff3].collect { |x| params[x] }
  end

  def_ordered(:sequential, String, [Integer, :optional]) do |params|
    params
  end

  def_ordered(:ranged, (0..9)) do |params|
    params
  end

  def_attr(:set_me, String)

  def_ordered(:proc_nil, proc { |x| x.nil? }) do |params|
    params
  end

  def_ordered(:proc_raise, proc { |x| ArgumentError.new("foo") }) do |params|
    params
  end

  def_named(:has_named_rt, :stuff => {:respond_to => :replace}) do |params|
    params[:stuff]
  end

  def_ordered(:has_ordered_rt, {:respond_to => :replace}) do |params|
    params[0]
  end

  def_attr :rt, {:respond_to => :replace}
end

$named_proc = build_named(:stuff => String) do |params|
  params
end

$ordered_proc = build_ordered((0..9)) do |params|
  params
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

    assert_equal($named_proc.call(:stuff => "foo"), { :stuff => "foo" })
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
      assert_equal($ordered_proc.call(5), [5])
    end

    def test_04_procs
      assert(@checked.respond_to?(:proc_nil))

      assert_raises(ArgumentError.new("value of argument '0' does not pass custom validation.")) do
        @checked.proc_nil(true)
      end

      assert_equal(@checked.proc_nil(nil), [nil])

      assert(@checked.respond_to?(:proc_nil))

      assert_raises(ArgumentError.new("foo")) do
        @checked.proc_raise(true)
      end

      assert_equal(@checked.proc_nil(nil), [nil])
    end

    def test_05_attr
      assert(@checked.respond_to?(:set_me))

      assert_raises(ArgumentError.new("value of argument '0' is an invalid type. Requires 'String'")) do
        @checked.set_me = 0
      end

      @checked.set_me = "Foo"

      assert_equal(@checked.set_me, "Foo")
    end

    def test_06_respond_to
      assert(@checked.respond_to?(:has_named_rt))
      assert(@checked.respond_to?(:has_ordered_rt))
      assert(@checked.respond_to?(:rt))

      assert_raises(ArgumentError.new("value of argument '0' does not respond to 'replace'")) do
        @checked.rt = nil
      end

      assert_raises(ArgumentError.new("value of argument '0' does not respond to 'replace'")) do
        @checked.has_ordered_rt(nil)
      end

      assert_raises(ArgumentError.new("value of argument 'stuff' does not respond to 'replace'")) do
        @checked.has_named_rt(:stuff => nil)
      end

      @checked.rt = "foo"

      assert(@checked.rt, "foo")
      assert(@checked.has_ordered_rt("foo"), "foo")
      assert(@checked.has_named_rt(:stuff => "foo"), "foo")
    end
end
