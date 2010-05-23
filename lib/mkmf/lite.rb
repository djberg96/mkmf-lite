require 'erb'
require 'rbconfig'
require 'tmpdir'
require 'ptools'

module Mkmf
  module Lite
    # The version of the mkmf-lite library
    MKMF_LITE_VERSION = '0.1.0'

    @@cpp_command   = Config::CONFIG['CC'] || Config::CONFIG['CPP']
    @@cpp_outfile   = Config::CONFIG['CPPOUTFILE'] # -o conftest.i
    @@cpp_libraries = Config::CONFIG['LIBS'] + Config::CONFIG['LIBRUBYARG']
    @@cpp_srcfile   = 'conftest.c'

    # Check for the presence of the given +header+ file.
    #
    # Returns true if found, or false if not found.
    #
    def have_header(header)
      erb  = ERB.new(read_template('have_header.erb'))
      result = erb.result(binding)
      try_to_compile(result)
    end

    # Check for the presence of the given +function+ in the common header
    # files, or within any +headers+ that you provide.
    #
    # Returns true if found, or false if not found.
    #
    def have_func(function, headers = [])
      headers = [headers] unless headers.is_a?(Array)

      unless Config::CONFIG['COMMON_HEADERS'].empty?
        headers += Config::CONFIG['COMMON_HEADERS']
      end

      headers  = headers.flatten.uniq
      includes = headers.map{ |h| "#include <#{h}>" }.join("\n")

      erb_ptr = ERB.new(read_template('have_func_pointer.erb'))
      erb_std = ERB.new(read_template('have_func.erb'))

      pointer  = erb_ptr.result(binding)
      standard = erb_std.result(binding)

      # Check for just the function pointer first. If that fails, then try
      # to compile with the function declaration.
      try_to_compile(pointer) || try_to_compile(standard)
    end

    private

    # Create a temporary bit of C source code in the temp directory, and
    # try to compile it. If it succeeds, return true. Otherwise, return
    # false.
    #
    # Note that $stderr is temporarily redirected to the null device because
    # we don't actually care about the reason for failure.
    #
    def try_to_compile(code)
      begin
        bool = false
        stderr_orig = $stderr.dup

        Dir.chdir(Dir.tmpdir){
          File.open(@@cpp_srcfile, 'w'){ |fh| fh.write(code) }

          command  = @@cpp_command + ' '
          command += @@cpp_libraries + ' '
          command += @@cpp_outfile + ' '
          command += @@cpp_srcfile

          $stderr.reopen(File.null)
          bool = system(command)
        }
      ensure
        File.delete(@@cpp_srcfile) if File.exists?(@@cpp_srcfile)
        File.delete(@@cpp_outfile) if File.exists?(@@cpp_outfile)
        $stderr.reopen(stderr_orig)
      end

      bool
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
