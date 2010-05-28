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
    main = eval("self", TOPLEVEL_BINDING)
    MethLab.integrate

    module_methods = Module.instance_methods
    main_methods   = main.methods

    assert(module_methods.include?(:def_named)     || module_methods.include?("def_named"))
    assert(module_methods.include?(:def_ordered)   || module_methods.include?("def_ordered"))
    assert(module_methods.include?(:build_named)   || module_methods.include?("build_named"))
    assert(module_methods.include?(:build_ordered) || module_methods.include?("build_ordered"))
    assert(module_methods.include?(:inline)        || module_methods.include?("inline"))

    assert(main_methods.include?(:def_named)     || main_methods.include?("def_named"))
    assert(main_methods.include?(:def_ordered)   || main_methods.include?("def_ordered"))
    assert(main_methods.include?(:build_named)   || main_methods.include?("build_named"))
    assert(main_methods.include?(:build_ordered) || main_methods.include?("build_ordered"))
    assert(main_methods.include?(:inline)        || main_methods.include?("inline"))
  end
end
