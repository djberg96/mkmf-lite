require 'erb'
require 'rbconfig'
require 'tmpdir'
require 'ptools'

module Mkmf
  module Lite
    # The version of the mkmf-lite library
    MKMF_LITE_VERSION = '0.2.2'

    @@cpp_command = Config::CONFIG['CC'] || Config::CONFIG['CPP']
    @@cpp_outfile = Config::CONFIG['CPPOUTFILE'] || "-o conftest.i"
    @@cpp_srcfile = 'conftest.c'

    if Config::CONFIG['LIBS']
      @@cpp_libraries = Config::CONFIG['LIBS'] + Config::CONFIG['LIBRUBYARG']
    else
      # TODO: We should adjust this based on OS. For now we're using
      # arguments I think you'll typically see set on Linux and BSD.
      @@cpp_libraries = "-lrt -ldl -lcrypt -lm"
    end

    # JRuby, and possibly others
    unless @@cpp_command
      case Config::CONFIG['host_os']
        when /msdos|mswin|win32|windows|mingw|cygwin/i
          @@cpp_command = File.which('cl') || File.which('gcc')
        when /sunos|solaris|hpux/i
          @@cpp_command = File.which('cc') || File.which('gcc')
        else
          @@cpp_command = 'gcc'
      end
    end

    # Check for the presence of the given +header+ file.
    #
    # Returns true if found, or false if not found.
    #
    def have_header(header)
      erb = ERB.new(read_template('have_header.erb'))
      code = erb.result(binding)
      try_to_compile(code)
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
    # +struct_member+.  If it does not, or the struct type cannot be found,
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

      common_headers = Config::CONFIG['COMMON_HEADERS']

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
    # try to compile it. If it succeeds, return true. Otherwise, return
    # false.
    #
    # Note that $stderr is temporarily redirected to the null device because
    # we don't actually care about the reason for failure.
    #
    def try_to_compile(code)
      begin
        boolean = false
        stderr_orig = $stderr.dup

        Dir.chdir(Dir.tmpdir){
          File.open(@@cpp_srcfile, 'w'){ |fh| fh.write(code) }

          command  = @@cpp_command + ' '
          command += @@cpp_outfile + ' '
          command += @@cpp_srcfile

          $stderr.reopen(File.null)
          boolean = system(command)
        }
      ensure
        File.delete(@@cpp_srcfile) if File.exists?(@@cpp_srcfile)
        File.delete(@@cpp_outfile) if File.exists?(@@cpp_outfile)
        $stderr.reopen(stderr_orig)
      end

      boolean
    end

    # Slurp the contents of the template file for evaluation later.
    #
    def read_template(file)
      IO.read(get_template_file(file))
    end

    # Retrieve the path to the template +file+ name.
    #
    def get_template_file(file)
      File.join(File.dirname(__FILE__), 'templates', file)
    end
  end
end
