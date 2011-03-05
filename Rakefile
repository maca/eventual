require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name                 = "eventual"
    gem.summary              = %Q{ Reconocimiento de fechas y periodos en lenguaje natural. Natural language date and period parsing, currently only in spanish. }
    gem.description          = %Q{ Reconocimiento de fechas y periodos en lenguaje natural. Natural language date and period parsing, currently only in spanish. }
    gem.email                = "macarui@gmail.com"
    gem.homepage             = "http://github.com/maca/eventual"
    gem.authors              = ["Macario Ortega"]
    gem.add_dependency "treetop", ">= 1.4.5"
    gem.add_development_dependency "rspec", ">= 1.2.9"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "eventual #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
