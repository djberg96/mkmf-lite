require 'erb'
require 'rbconfig'
require 'tmpdir'
require 'ptools'

module Mkmf
  module Lite
    @@cpp_command = Config::CONFIG['CC'] || Config::CONFIG['CPP']
    @@cpp_outfile = Config::CONFIG['CPPOUTFILE'] # -o conftest.i
    @@cpp_srcfile = 'conftest.c'
    
    # Check for the presence of the given +header+ file.
    #
    def have_header(header)
      erb  = ERB.new(read_template('have_header.template'))
      result = erb.result(binding)
      try_to_compile(result)
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
          command = @@cpp_command << ' ' << @@cpp_outfile << ' ' << @@cpp_srcfile
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
