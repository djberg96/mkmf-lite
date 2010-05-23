########################################################################
# test_mkmf_lite.rb
#
# Tests for the mkmf-lite library.
########################################################################
require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'mkmf/lite'

class TC_Mkmf_Lite < Test::Unit::TestCase
  include Mkmf::Lite

  test "version information" do
    assert_equal('0.1.0', MKMF_LITE_VERSION)
  end

  test "have_header basic functionality" do
    assert_respond_to(self, :have_header)
  end

  test "have_header returns expected boolean value" do
    assert_true(have_header('stdio.h'))
    assert_false(have_header('foobar.h'))
  end

  test "have_header requires one argument only" do
    assert_raise(ArgumentError){ have_header }
    assert_raise(ArgumentError){ have_header('stdio.h', 'stdlib.h') }
  end

  test "have_func basic functionality" do
    assert_respond_to(self, :have_func)
  end

  test "have_func with no arguments returns expected boolean value" do
    assert_true(have_func('abort'))
    assert_false(have_header('abortxyz'))
  end

  test "have_func with arguments returns expected boolean value" do
    assert_true(have_func('printf', 'stdio.h'))
    assert_false(have_func('printfx', 'stdio.h'))
  end

  test "have_func requires at least one argument" do
    assert_raise(ArgumentError){ have_func }
  end

  test "have_func accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ have_func('printf', 'stdio.h', 'bogus') }
  end
end
