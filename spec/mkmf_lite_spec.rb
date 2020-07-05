########################################################################
# mkmf_lite_spec.rb
#
# Tests for the mkmf-lite library.
########################################################################
require 'rubygems'
require 'rspec'
require 'mkmf/lite'

describe Mkmf::Lite do
  subject { Class.new{ |obj| obj.extend Mkmf::Lite } }

  let(:windows) {  File::ALT_SEPARATOR }

  before do
    @st_type   = 'struct stat'
    @st_member = 'st_uid'
    @st_header = 'sys/stat.h'
  end

  describe "constants" do
    example "version information" do
      expect(described_class::MKMF_LITE_VERSION).to eq('0.4.0')
      expect(described_class::MKMF_LITE_VERSION).to be_frozen
    end
  end

  describe "have_header" do
    example "have_header basic functionality" do
      expect(subject).to respond_to(:have_header)
    end

    example "have_header returns expected boolean value" do
      expect(subject.have_header('stdio.h')).to eq(true)
      expect(subject.have_header('foobar.h')).to eq(false)
    end

    example "have_header accepts an array of directories as a second argument" do
      expect{ subject.have_header('stdio.h', '/usr/local/include') }.not_to raise_error
      expect{ subject.have_header('stdio.h', '/usr/local/include', '/usr/include') }.not_to raise_error
    end
  end

=begin
  example "have_func basic functionality" do
    expect(self).to respond_to(:have_func)
  end

  example "have_func with no arguments returns expected boolean value" do
    expect(have_func('abort')).to be_true
    expect(have_func('abortxyz')).to be_false
  end

  example "have_func with arguments returns expected boolean value" do
    expect(have_func('printf', 'stdio.h')).to be_true
    expect(have_func('printfx', 'stdio.h')).to be_false
  end

  example "have_func requires at least one argument" do
    expect{ have_func }.to raise_error(ArgumentError)
  end

  example "have_func accepts a maximum of two arguments" do
    expect{ have_func('printf', 'stdio.h', 'bogus') }.to raise_error(ArgumentError)
  end

  example "have_struct_member basic functionality" do
    expect(self).to respond_to(:have_struct_member)
  end

  example "have_struct_member returns expected boolean value" do
    expect(have_struct_member(@st_type, @st_member, @st_header)).to be_true
    expect(have_struct_member(@st_type, 'pw_bogus', @st_header)).to be_false
    expect(have_struct_member(@st_type, @st_member)).to be_false
  end

  example "have_struct_member requires at least two arguments" do
    expect{ have_struct_member() }.to raise_error(ArgumentError)
    expect{ have_struct_member('struct passwd') }.to raise_error(ArgumentError)
  end

  example "have_struct_member accepts a maximum of three arguments" do
    assert_raise(ArgumentError){
      have_struct_member('struct passwd', 'pw_name', 'pwd.h', true)
    }
  end

  example "check_sizeof basic functionality" do
    expect(self).to respond_to(:check_sizeof)
    expect{ check_sizeof(@st_type, @st_header) }.not_to raise_error
  end

  example "check_sizeof requires at least one argument" do
    expect{ check_sizeof }.to raise_error(ArgumentError)
    expect{ check_sizeof('struct passwd', 'pw_name', 1) }.to raise_error(ArgumentError)
  end

  example "check_sizeof accepts a maximum of two arguments" do
    expect{ check_sizeof('div_t', 'stdlib.h', 1) }.to raise_error(ArgumentError)
  end

  example "check_sizeof works with one or two arguments" do
    expect{ check_sizeof('div_t') }.not_to raise_error
    expect{ check_sizeof('div_t', 'stdlib.h') }.not_to raise_error
  end

  example "check_sizeof returns an integer value" do
    size = check_sizeof(@st_type, @st_header)
    expect( size).to be_kind_of(Integer)
    expect(size > 0).to be_true
  end
=end

  after do
    @st_type   = nil
    @st_member = nil
    @st_header = nil
  end
end
