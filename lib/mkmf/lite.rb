# frozen_string_literal: true

require 'erb'
require 'rbconfig'
require 'tmpdir'
require 'open3'
require 'shellwords'
require 'ptools'
require 'memoist'

# The Mkmf module serves as a namespace only.
module Mkmf
  # The Lite module scopes the Mkmf module to differentiate it from the
  # Mkmf module in the standard library.
  module Lite
    extend Memoist

    # The version of the mkmf-lite library
    MKMF_LITE_VERSION = '0.8.0'

    private

    def cpp_defs
      RbConfig::CONFIG['DEFS']
    end

    def jruby?
      defined?(JRUBY_VERSION)
    end

    memoize :jruby?

    def windows_with_cl_compiler?
      File::ALT_SEPARATOR && RbConfig::CONFIG['CPP']&.match?(/^cl/)
    end

    memoize :windows_with_cl_compiler?

    # rubocop:disable Layout/LineLength
    def cpp_command
      command = RbConfig::CONFIG['CC'] || RbConfig::CONFIG['CPP'] || File.which('cc') || File.which('gcc') || File.which('cl')
      raise StandardError, 'Compiler not found' unless command

      command
    end
    # rubocop:enable Layout/LineLength

    memoize :cpp_command

    def cpp_source_file
      'conftest.c'
    end

    def cpp_out_file(output_file = 'conftest.exe')
      if windows_with_cl_compiler?
        "/Fe#{output_file}"
      else
        ['-o', output_file]
      end
    end

    def cpp_libraries
      nil
    end

    memoize :cpp_libraries

    def cpp_library_paths
      paths = []

      # Add Homebrew library paths on macOS
      if RbConfig::CONFIG['host_os'].match?(/darwin/)
        # Apple Silicon Macs
        paths << '-L/opt/homebrew/lib' if File.directory?('/opt/homebrew/lib')
        # Intel Macs
        paths << '-L/usr/local/lib' if File.directory?('/usr/local/lib')
      end

      paths.empty? ? nil : paths
    end

    memoize :cpp_library_paths

    public

    # Check for the presence of the given +header+ file. You may optionally
    # provide a list of directories to search.
    #
    # Returns true if found, or false if not found.
    #
    def have_header(header, *directories)
      erb = ERB.new(read_template('have_header.erb'))
      code = erb.result(binding)
      options = build_directory_options(directories)

      try_to_compile(code, options)
    end

    memoize :have_header

    # Check for the presence of the given +function+ in the common header
    # files, or within any +headers+ that you provide.
    #
    # Returns true if found, or false if not found.
    #
    def have_func(function, headers = [])
      headers = get_header_string(headers)

      erb_ptr = ERB.new(read_template('have_func_pointer.erb'))
      erb_std = ERB.new(read_template('have_func.erb'))

      ptr_code = erb_ptr.result(binding)
      std_code = erb_std.result(binding)

      # Check for just the function pointer first. If that fails, then try
      # to compile with the function declaration.
      try_to_compile(ptr_code) || try_to_compile(std_code)
    end

    memoize :have_func

    # Check for the presence of the given +library+. You may optionally
    # provide a +function+ name to check for within that library, as well
    # as any additional +headers+.
    #
    # Returns true if the library can be linked, or false otherwise.
    #
    # Note: The library name should not include the 'lib' prefix or file
    # extension. For example, use 'xerces-c' not 'libxerces-c' or 'libxerces-c.dylib'.
    # However, if the 'lib' prefix is provided, it will be automatically stripped.
    #
    def have_library(library, function = nil, headers = [])
      # Strip 'lib' prefix if present (e.g., 'libxerces-c' -> 'xerces-c')
      library = library.sub(/^lib/, '') unless windows_with_cl_compiler?

      headers = get_header_string(headers)
      erb = ERB.new(read_template('have_library.erb'))
      code = erb.result(binding)

      # Build link options with the library
      link_options = windows_with_cl_compiler? ? "#{library}.lib" : "-l#{library}"

      try_to_compile(code, nil, link_options)
    end

    memoize :have_library

    # Checks whether or not the struct of type +struct_type+ contains the
    # +struct_member+. If it does not, or the struct type cannot be found,
    # then false is returned.
    #
    # An optional list of +headers+ may be specified, in addition to the
    # common header files that are already searched.
    #
    def have_struct_member(struct_type, struct_member, headers = [])
      headers = get_header_string(headers)
      erb = ERB.new(read_template('have_struct_member.erb'))
      code = erb.result(binding)

      try_to_compile(code)
    end

    memoize :have_struct_member

    # Returns the value of the given +constant+ (which could also be a macro)
    # using +headers+, or common headers if no headers are specified.
    #
    # If this method fails an error is raised. This could happen if the constant
    # can't be found and/or the header files do not include the indicated constant.
    #
    def check_valueof(constant, headers = [], *directories)
      headers = get_header_string(headers)
      erb = ERB.new(read_template('check_valueof.erb'))
      code = erb.result(binding)
      options = build_directory_options(directories)

      try_to_execute(code, options)
    end

    memoize :check_valueof

    # Returns the sizeof +type+ using +headers+, or common headers if no
    # headers are specified.
    #
    # If this method fails an error is raised. This could happen if the type
    # can't be found and/or the header files do not include the indicated type.
    #
    # Example:
    #
    #   class Foo
    #     include Mkmf::Lite
    #     utsname = check_sizeof('struct utsname', 'sys/utsname.h')
    #   end
    #
    def check_sizeof(type, headers = [], *directories)
      headers = get_header_string(headers)
      erb = ERB.new(read_template('check_sizeof.erb'))
      code = erb.result(binding)
      options = build_directory_options(directories)

      try_to_execute(code, options)
    end

    memoize :check_sizeof

    # Returns the offset of +field+ within +struct_type+ using +headers+,
    # or common headers, plus stddef.h, if no headers are specified.
    #
    # If this method fails an error is raised. This could happen if the field
    # can't be found and/or the header files do not include the indicated type.
    # It will also fail if the field is a bit field.
    #
    # Example:
    #
    #   class Foo
    #     include Mkmf::Lite
    #     utsname = check_offsetof('struct utsname', 'release', 'sys/utsname.h')
    #   end
    #
    def check_offsetof(struct_type, field, headers = [], *directories)
      headers = get_header_string(headers)
      erb = ERB.new(read_template('check_offsetof.erb'))
      code = erb.result(binding)
      options = build_directory_options(directories)

      try_to_execute(code, options)
    end

    memoize :check_offsetof

    private

    def build_directory_options(directories)
      return nil if directories.empty?

      directories.flatten.map { |dir| "-I#{dir}" }
    end

    def build_compile_command(command_options = nil, library_options = nil, paths = {})
      source_file = paths.fetch(:source_file, cpp_source_file)
      output_file = paths.fetch(:output_file, 'conftest.exe')

      command_parts = shellwords(cpp_command)
      command_parts.concat(shellwords(command_options))
      command_parts.concat(shellwords(cpp_library_paths))
      command_parts.concat(shellwords(cpp_libraries))
      command_parts.concat(shellwords(cpp_defs))
      command_parts.concat(shellwords(cpp_out_file(output_file)))
      command_parts << source_file
      command_parts.concat(shellwords(library_options))

      command_parts
    end

    def shellwords(options)
      if options.is_a?(Array)
        options.flatten.compact.map(&:to_s)
      else
        Shellwords.split(options.to_s)
      end
    end

    # Take an array of header file names (or convert it to an array if it's a
    # single argument), add the COMMON_HEADERS, flatten it out and remove any
    # duplicates.
    #
    # Finally, convert the result into a single string of '#include'
    # directives, each separated by a newline.
    #
    # This string is then to be used at the top of the ERB templates.
    #
    def get_header_string(headers)
      headers = Array(headers)

      common_headers = RbConfig::CONFIG['COMMON_HEADERS']

      if common_headers.nil? || common_headers.empty?
        if headers.empty?
          headers = ['stdio.h', 'stdlib.h']
          headers << 'windows.h' if File::ALT_SEPARATOR
        end
      else
        headers += common_headers.split
      end

      headers.flatten.uniq.map { |h| "#include <#{h}>" }.join("\n")
    end

    # Create a temporary bit of C source code in the temp directory, and
    # try to compile it. If it succeeds attempt to run the generated code.
    # The code generated is expected to print a number to STDOUT, which
    # is then grabbed and returned as an integer.
    #
    def try_to_execute(code, command_options = nil)
      result = 0

      Dir.mktmpdir('mkmf-lite') do |dir|
        source_file = File.join(dir, cpp_source_file)
        output_file = File.join(dir, 'conftest.exe')
        File.write(source_file, code)
        command = build_compile_command(
          command_options,
          nil,
          :source_file => source_file,
          :output_file => output_file
        )

        _stdout, stderr, status = Open3.capture3(*command)

        if status.success?
          output, = Open3.capture2(output_file)
          result = output.chomp.to_i
        else
          message = "Failed to compile source code with command '#{command.shelljoin}':\n#{stderr}===\n#{code}==="
          raise StandardError, message
        end
      end

      result
    end

    # Create a temporary bit of C source code in the temp directory, and
    # try to compile it. If it succeeds, return true. Otherwise, return
    # false.
    #
    def try_to_compile(code, command_options = nil, library_options = nil)
      Dir.mktmpdir('mkmf-lite') do |dir|
        source_file = File.join(dir, cpp_source_file)
        output_file = File.join(dir, 'conftest.exe')
        File.write(source_file, code)
        command = build_compile_command(
          command_options,
          library_options,
          :source_file => source_file,
          :output_file => output_file
        )

        _stdout, _stderr, status = Open3.capture3(*command)
        status.success?
      end
    end

    # Slurp the contents of the template file for evaluation later.
    #
    def read_template(file)
      File.read(get_template_file(file))
    end

    # Retrieve the path to the template +file+ name.
    #
    def get_template_file(file)
      File.join(File.dirname(__FILE__), 'templates', file)
    end
  end
end
