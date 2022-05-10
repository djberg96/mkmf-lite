require 'erb'
require 'rbconfig'
require 'tmpdir'
require 'open3'
require 'ptools'

module Mkmf
  module Lite
    # The version of the mkmf-lite library
    MKMF_LITE_VERSION = '0.5.1'.freeze

    private

    def cpp_command
      command = RbConfig::CONFIG['CC'] || RbConfig::CONFIG['CPP'] || File.which('cc') || File.which('gcc') || File.which('cl')
      raise 'Compiler not found' unless command
      command
    end

    def cpp_source_file
      'conftest.c'
    end

    def cpp_out_file
      if File::ALT_SEPARATOR && RbConfig::CONFIG['CPP'] =~ /^cl/
        '/Feconftest.exe'
      else
        '-o conftest.exe'
      end
    end

    # TODO: We should adjust this based on OS. For now we're using
    # arguments I think you'll typically see set on Linux and BSD.
    def cpp_libraries
      if RbConfig::CONFIG['LIBS']
        RbConfig::CONFIG['LIBS'] + RbConfig::CONFIG['LIBRUBYARG']
      else
        '-lrt -ldl -lcrypt -lm'
      end
    end

    public

    # Check for the presence of the given +header+ file. You may optionally
    # provide a list of directories to search.
    #
    # Returns true if found, or false if not found.
    #
    def have_header(header, *directories)
      erb = ERB.new(read_template('have_header.erb'))
      code = erb.result(binding)

      if directories.empty?
        options = nil
      else
        options = ''
        directories.each{ |dir| options += "-I#{dir} " }
        options.rstrip!
      end

      try_to_compile(code, options)
    end

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

    # Returns the value of the given +constant+ (which could also be a macro)
    # using +headers+, or common headers if no headers are specified.
    #
    # If this method fails an error is raised. This could happen if the constant
    # can't be found and/or the header files do not include the indicated constant.
    #
    def check_valueof(constant, headers = [])
      headers = get_header_string(headers)
      erb = ERB.new(read_template('check_valueof.erb'))
      code = erb.result(binding)

      try_to_execute(code)
    end

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
    def check_sizeof(type, headers = [])
      headers = get_header_string(headers)
      erb = ERB.new(read_template('check_sizeof.erb'))
      code = erb.result(binding)

      try_to_execute(code)
    end

    private

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
      headers = [headers] unless headers.is_a?(Array)

      common_headers = RbConfig::CONFIG['COMMON_HEADERS']

      if common_headers.nil? || common_headers.empty?
        if headers.empty?
          headers = ['stdio.h', 'stdlib.h']
          headers += 'windows.h' if File::ALT_SEPARATOR
        end
      else
        headers += common_headers.split
      end

      headers = headers.flatten.uniq
      headers = headers.map{ |h| "#include <#{h}>" }.join("\n")

      headers
    end

    # Create a temporary bit of C source code in the temp directory, and
    # try to compile it. If it succeeds attempt to run the generated code.
    # The code generated is expected to print a number to STDOUT, which
    # is then grabbed and returned as an integer.
    #
    # Note that $stderr is temporarily redirected to the null device because
    # we don't actually care about the reason for failure, though a Ruby
    # error is raised if the compilation step fails.
    #
    def try_to_execute(code)
      begin
        result = 0

        stderr_orig = $stderr.dup
        stdout_orig = $stdout.dup

        Dir.chdir(Dir.tmpdir){
          File.open(cpp_source_file, 'w'){ |fh| fh.write(code) }

          command  = cpp_command + ' '
          command += cpp_out_file + ' '
          command += cpp_source_file

          # Temporarily close these
          $stderr.reopen(IO::NULL)
          $stdout.reopen(IO::NULL)

          if system(command)
            $stdout.reopen(stdout_orig) # We need this back for open3 to work.

            conftest = File::ALT_SEPARATOR ? 'conftest.exe' : './conftest.exe'

            Open3.popen3(conftest) do |stdin, stdout, stderr|
              stdin.close
              stderr.close
              result = stdout.gets.chomp.to_i
            end
          else
            raise "Failed to compile source code with command '#{command}':\n===\n" + code + '==='
          end
        }
      ensure
        File.delete(cpp_source_file) if File.exist?(cpp_source_file)
        File.delete(cpp_out_file) if File.exist?(cpp_out_file)
        $stderr.reopen(stderr_orig)
        $stdout.reopen(stdout_orig)
      end

      result
    end

    # Create a temporary bit of C source code in the temp directory, and
    # try to compile it. If it succeeds, return true. Otherwise, return
    # false.
    #
    # Note that $stderr is temporarily redirected to the null device because
    # we don't actually care about the reason for failure.
    #
    def try_to_compile(code, command_options = nil)
      begin
        boolean = false
        stderr_orig = $stderr.dup
        stdout_orig = $stdout.dup

        Dir.chdir(Dir.tmpdir){
          File.open(cpp_source_file, 'w'){ |fh| fh.write(code) }

          if command_options
            command  = cpp_command + ' ' + command_options + ' '
          else
            command  = cpp_command + ' '
          end

          command += cpp_out_file + ' '
          command += cpp_source_file

          $stderr.reopen(IO::NULL)
          $stdout.reopen(IO::NULL)
          boolean = system(command)
        }
      ensure
        File.delete(cpp_source_file) if File.exist?(cpp_source_file)
        File.delete(cpp_out_file) if File.exist?(cpp_out_file)
        $stdout.reopen(stdout_orig)
        $stderr.reopen(stderr_orig)
      end

      boolean
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
