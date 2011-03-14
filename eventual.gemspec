# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eventual/version"

Gem::Specification.new do |s|
  s.name        = 'eventual'
  s.version     = Eventual::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Macario Ortega"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = "http://github.com/maca/eventual"
  s.summary     = %Q{Reconocimiento de fechas y periodos en lenguaje natural. Natural language date and period parsing in spanish.}
  s.description = %Q{Reconocimiento de fechas y periodos en lenguaje natural. Natural language date and period parsing in spanish.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'

  s.add_dependency 'treetop'
end
