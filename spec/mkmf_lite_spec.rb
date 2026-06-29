# frozen_string_literal: true

########################################################################
# mkmf_lite_spec.rb
#
# Tests for the mkmf-lite library.
########################################################################
require 'rubygems'
require 'rspec'
require 'mkmf/lite'
require 'fileutils'
require 'tmpdir'

RSpec.describe Mkmf::Lite do
  subject { Class.new{ |obj| obj.extend Mkmf::Lite } }

  def template_source(file)
    File.read(File.expand_path("../lib/mkmf/templates/#{file}", __dir__))
  end

  let(:st_type)   { 'struct stat' }
  let(:st_member) { 'st_uid' }
  let(:st_header) { 'sys/stat.h' }
  let(:constant)  { 'EOF' }

  describe 'constants' do
    example 'version information' do
      expect(described_class::MKMF_LITE_VERSION).to eq('0.8.0')
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

    example 'have_header accepts a directory with spaces' do
      Dir.mktmpdir('mkmf lite') do |dir|
        header = 'mkmf_lite_space_header.h'

        File.write(File.join(dir, header), "#define MKMF_LITE_SPACE_HEADER 1\n")

        expect(subject.have_header(header, dir)).to be(true)
      end
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
      expect{ subject.have_struct_member('struct passwd', 'pw_name', 'pwd.h', 1) }.to raise_error(ArgumentError)
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

    example 'check_valueof accepts directory arguments' do
      expect{ subject.check_valueof(constant, 'stdio.h', ['/usr/include']) }.not_to raise_error
    end

    example 'check_valueof works with one or two arguments' do
      expect{ subject.check_valueof(constant) }.not_to raise_error
      expect{ subject.check_valueof(constant, 'stdio.h') }.not_to raise_error
    end

    example 'check_valueof returns an integer value' do
      value = subject.check_valueof(constant)
      expect(value).to be_a(Integer)
      expect(value).to eq(-1)
    end

    example 'check_valueof returns a wider than int integer value' do
      char_bit = subject.check_valueof('CHAR_BIT', 'limits.h')
      ullong_size = subject.check_sizeof('unsigned long long', 'limits.h')
      value = subject.check_valueof('ULLONG_MAX', 'limits.h')

      expect(value).to be_a(Integer)
      expect(value).to eq((1 << (ullong_size * char_bit)) - 1)
    end

    example 'check_valueof generates portable integer formatting' do
      source = template_source('check_valueof.erb')

      expect(source).to include('#include <stdint.h>', '#include <inttypes.h>')
      expect(source).to include('PRIdMAX', 'PRIuMAX')
      expect(source).not_to include('printf("%d')
    end
  end

  context 'check_offsetof' do
    let(:st_field){ 'st_dev' }

    example 'check_offsetof basic functionality' do
      expect(subject).to respond_to(:check_offsetof)
      expect{ subject.check_offsetof(st_type, st_field, st_header) }.not_to raise_error
    end

    example 'check_offsetof requires at least two arguments' do
      expect{ subject.check_offsetof }.to raise_error(ArgumentError)
      expect{ subject.check_offsetof(st_type) }.to raise_error(ArgumentError)
    end

    example 'check_offsetof accepts directory arguments' do
      expect{ subject.check_offsetof(st_type, st_field, [st_header, 'stdlib.h'], ['/usr/include']) }.not_to raise_error
    end

    example 'check_offsetof returns an integer value' do
      size1 = subject.check_offsetof(st_type, st_field, st_header)
      size2 = subject.check_offsetof(st_type, 'st_ino', st_header)
      expect(size1).to be_a(Integer)
      expect(size2).to be_a(Integer)
      expect(size1).to eq(0)
      expect(size2).to be > size1
    end

    example 'check_offsetof generates size_t output formatting' do
      source = template_source('check_offsetof.erb')

      expect(source).to include('printf("%zu\\n", offsetof(')
      expect(source).not_to include('(int)(offsetof')
      expect(source).not_to include('printf("%d')
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

    example 'check_sizeof accepts directory arguments' do
      expect{ subject.check_sizeof('div_t', 'stdlib.h', ['/usr/include']) }.not_to raise_error
    end

    example 'check_sizeof works with one or two arguments' do
      expect{ subject.check_sizeof('div_t') }.not_to raise_error
      expect{ subject.check_sizeof('div_t', 'stdlib.h') }.not_to raise_error
    end

    example 'check_sizeof returns an integer value' do
      size = subject.check_sizeof(st_type, st_header)
      expect(size).to be_a(Integer)
      expect(size).to be > 0
    end

    example 'check_sizeof generates size_t output formatting' do
      source = template_source('check_sizeof.erb')

      expect(source).to include('printf("%zu\\n", sizeof(')
      expect(source).not_to include('(int)(sizeof')
      expect(source).not_to include('printf("%d')
    end
  end

  context 'have_library' do
    example 'have_library basic functionality' do
      expect(subject).to respond_to(:have_library)
    end

    example 'have_library returns expected boolean value' do
      expect(subject.have_library('c')).to be(true)
      expect(subject.have_library('m')).to be(true)
      expect(subject.have_library('nonexistent_library_xyz')).to be(false)
    end

    example 'have_library with function argument returns expected boolean value' do
      expect(subject.have_library('m', 'sqrt', 'math.h')).to be(true)
      expect(subject.have_library('m', 'nonexistent_function_xyz', 'math.h')).to be(false)
    end

    example 'have_library with headers argument works correctly' do
      expect{ subject.have_library('m', 'sqrt', 'math.h') }.not_to raise_error
      expect(subject.have_library('m', 'sqrt', 'math.h')).to be(true)
    end

    example 'have_library requires at least one argument' do
      expect{ subject.have_library }.to raise_error(ArgumentError)
    end

    example 'have_library accepts a maximum of three arguments' do
      expect{ subject.have_library('m', 'sqrt', 'math.h', 'bogus') }.to raise_error(ArgumentError)
    end
  end

  describe 'command construction' do
    let(:command_with_spaces) do
      subject.send(
        :build_compile_command,
        ['-I/tmp/include dir'],
        nil,
        :source_file => 'source.c',
        :output_file => 'output file'
      )
    end

    example 'build_compile_command returns argv-style command parts' do
      expect(command_with_spaces).to include('-I/tmp/include dir')
      expect(command_with_spaces).to include('source.c')
      expect(command_with_spaces.any? { |part| part.include?('output file') }).to be(true)
    end

    example 'build_compile_command does not include implicit Linux libraries' do
      command = subject.send(:build_compile_command)

      expect(command).not_to include('-Lrt', '-Ldl', '-Lcrypt', '-Lm')
      expect(command).not_to include('-lrt', '-ldl', '-lcrypt', '-lm')
    end
  end
end
