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

  def self.startup
    @@windows = Config::CONFIG['host_os'] =~ /mswin|msdos|win32|mingw|cygwin/i
  end

  def setup
    @st_type   = 'struct stat'
    @st_member = 'st_uid'
    @st_header = 'sys/stat.h' 
  end

  test "version information" do
    assert_equal('0.2.0', MKMF_LITE_VERSION)
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

  test "have_struct_member basic functionality" do
    assert_respond_to(self, :have_struct_member)
  end

  test "have_struct_member returns expected boolean value" do
    assert_true(have_struct_member(@st_type, @st_member, @st_header))
    assert_false(have_struct_member(@st_type, 'pw_bogus', @st_header))
    assert_false(have_struct_member(@st_type, @st_member))
  end

  test "have_struct_member requires at least two arguments" do
    assert_raise(ArgumentError){ have_struct_member() }
    assert_raise(ArgumentError){ have_struct_member('struct passwd') }
  end

  test "have_struct_member accepts a maximum of three arguments" do
    assert_raise(ArgumentError){
      have_struct_member('struct passwd', 'pw_name', 'pwd.h', true)
    }
  end

  def teardown
    @st_type   = nil
    @st_member = nil
    @st_header = nil
  end

  def self.shutdown
    @@windows = nil
  end
end
