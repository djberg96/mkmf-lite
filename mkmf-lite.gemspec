require 'rubygems'

Gem::Specification.new do |spec|
  spec.name      = 'mkmf-lite'
  spec.summary   = 'A lighter version of mkmf designed for use as a library'
  spec.version   = '0.2.3'
  spec.author    = 'Daniel J. Berger'
  spec.license   = 'Artistic 2.0'
  spec.email     = 'djberg96@gmail.com'
  spec.homepage  = 'http://www.rubyforge.org/projects/shards'
  spec.test_file = 'test/test_mkmf_lite.rb'
  spec.files     = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST']
  spec.rubyforge_project = 'shards'
   
  spec.add_dependency('ptools')
  spec.add_development_dependency('test-unit', '>= 2.1.2')

  spec.description = <<-EOF
    The mkmf-lite library is a light version of the the mkmf library
    designed for use as a library. It does not create packages, builds,
    or log files of any kind. Instead, it provides mixin methods that you
    can use in FFI or tests to check for the presence of header files,
    constants, and so on.
  EOF
end
