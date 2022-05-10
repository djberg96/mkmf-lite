# frozen_string_literal: true

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

  let(:st_type)   { 'struct stat' }
  let(:st_member) { 'st_uid' }
  let(:st_header) { 'sys/stat.h' }
  let(:constant)  { 'EOF' }

  describe 'constants' do
    example 'version information' do
      expect(described_class::MKMF_LITE_VERSION).to eq('0.5.1')
      expect(described_class::MKMF_LITE_VERSION).to be_frozen
    end
  end

  describe 'have_header' do
    example 'have_header basic functionality' do
      expect(subject).to respond_to(:have_header)
    end

    example 'have_header returns expected boolean value' do
      expect(subject.have_header('stdio.h')).to be(true)
      expect(subject.have_header('foobar.h')).to be(false)
    end

    example 'have_header accepts an array of directories as a second argument' do
      expect{ subject.have_header('stdio.h', '/usr/local/include') }.not_to raise_error
      expect{ subject.have_header('stdio.h', '/usr/local/include', '/usr/include') }.not_to raise_error
    end
  end

  context 'have_func' do
    example 'have_func basic functionality' do
      expect(subject).to respond_to(:have_func)
    end

    example 'have_func with no arguments returns expected boolean value' do
      expect(subject.have_func('abort')).to be(true)
      expect(subject.have_func('abortxyz')).to be(false)
    end

    example 'have_func with arguments returns expected boolean value' do
      expect(subject.have_func('printf', 'stdio.h')).to be(true)
      expect(subject.have_func('printfx', 'stdio.h')).to be(false)
    end

    example 'have_func requires at least one argument' do
      expect{ subject.have_func }.to raise_error(ArgumentError)
    end

    example 'have_func accepts a maximum of two arguments' do
      expect{ subject.have_func('printf', 'stdio.h', 'bogus') }.to raise_error(ArgumentError)
    end
  end

  context 'have_struct_member' do
    example 'have_struct_member basic functionality' do
      expect(subject).to respond_to(:have_struct_member)
    end

    example 'have_struct_member returns expected boolean value' do
      expect(subject.have_struct_member(st_type, st_member, st_header)).to be(true)
      expect(subject.have_struct_member(st_type, 'pw_bogus', st_header)).to be(false)
      expect(subject.have_struct_member(st_type, st_member)).to be(false)
    end

    example 'have_struct_member requires at least two arguments' do
      expect{ subject.have_struct_member() }.to raise_error(ArgumentError)
      expect{ subject.have_struct_member('struct passwd') }.to raise_error(ArgumentError)
    end

    example 'have_struct_member accepts a maximum of three arguments' do
      expect{ subject.have_struct_member('struct passwd', 'pw_name', 'pwd.h', true) }.to raise_error(ArgumentError)
    end
  end

  context 'check_valueof' do
    example 'check_valueof basic functionality' do
      expect(subject).to respond_to(:check_valueof)
      expect{ subject.check_sizeof(constant) }.not_to raise_error
    end

    example 'check_valueof requires at least one argument' do
      expect{ subject.check_valueof }.to raise_error(ArgumentError)
    end

    example 'check_valueof accepts a maximum of two arguments' do
      expect{ subject.check_valueof(constant, 'stdio.h', 1) }.to raise_error(ArgumentError)
    end

    example 'check_valueof works with one or two arguments' do
      expect{ subject.check_valueof(constant) }.not_to raise_error
      expect{ subject.check_valueof(constant, 'stdio.h') }.not_to raise_error
    end

    example 'check_valueof returns an integer value' do
      value = subject.check_valueof(constant)
      expect(value).to be_kind_of(Integer)
      expect(value).to eq(-1)
    end
  end

  context 'check_sizeof' do
    example 'check_sizeof basic functionality' do
      expect(subject).to respond_to(:check_sizeof)
      expect{ subject.check_sizeof(st_type, st_header) }.not_to raise_error
    end

    example 'check_sizeof requires at least one argument' do
      expect{ subject.check_sizeof }.to raise_error(ArgumentError)
    end

    example 'check_sizeof accepts a maximum of two arguments' do
      expect{ subject.check_sizeof('div_t', 'stdlib.h', 1) }.to raise_error(ArgumentError)
    end

    example 'check_sizeof works with one or two arguments' do
      expect{ subject.check_sizeof('div_t') }.not_to raise_error
      expect{ subject.check_sizeof('div_t', 'stdlib.h') }.not_to raise_error
    end

    example 'check_sizeof returns an integer value' do
      size = subject.check_sizeof(st_type, st_header)
      expect(size).to be_kind_of(Integer)
      expect(size).to be > 0
    end
  end
end
