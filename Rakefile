require 'rake'
require 'rake/testtask'
require 'rbconfig'


namespace 'gem' do
  desc 'Remove any existing .gem files'
  task :clean do
    Dir['**/*.gem'].each{ |f| File.delete(f) }
  end
  
  desc 'Create the mkmf-lite gem.'
  task :create => [:clean] do
    spec = eval(IO.read('mkmf-lite.gemspec'))
    Gem::Builder.new(spec).build
  end

  desc 'Install the mkmf-lite gem.'
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install #{file}"
  end
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end
