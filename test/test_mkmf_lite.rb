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

  test "have_header basic functionality" do
    assert_respond_to(self, :have_header)
  end

  test "have_header returns expected boolean value" do
    assert_true(have_header('stdio.h'))
    assert_false(have_header('foobar.h'))
  end
end
