require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'mkmf-lite'
  spec.summary    = 'A lighter version of mkmf designed for use as a library'
  spec.version    = '0.4.0'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Apache-2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/mkmf-lite'
  spec.test_file  = 'test/test_mkmf_lite.rb'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.extra_rdoc_files = Dir['*.rdoc']
   
  spec.add_dependency('ptools', '~> 1.3')
  spec.add_development_dependency('rspec', '~> 3.9')

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/mkmf-lite',
    'bug_tracker_uri'   => 'https://github.com/djberg96/mkmf-lite/issues',
    'changelog_uri'     => 'https://github.com/djberg96/mkmf-lite/blob/master/CHANGES.rdoc',
    'documentation_uri' => 'https://github.com/djberg96/mkmf-lite/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/mkmf-lite',
    'wiki_uri'          => 'https://github.com/djberg96/mkmf-lite/wiki'
  }

  spec.description = <<-EOF
    The mkmf-lite library is a light version of the the mkmf library
    designed for use as a library. It does not create packages, builds,
    or log files of any kind. Instead, it provides mixin methods that you
    can use in FFI or tests to check for the presence of header files,
    constants, and so on.
  EOF
end
