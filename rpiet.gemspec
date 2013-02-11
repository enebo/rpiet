# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rpiet/version"

Gem::Specification.new do |s|
  s.name        = 'rpiet'
  s.version     = RPiet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Thomas E. Enebo'
  s.email       = 'tom.enebo@gmail.com'
  s.homepage    = 'http://github.com/enebo/rpiet'
  s.summary     = 'A Piet runtime'
  s.description = 'An implementation of the esoteric programming language Piet'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.has_rdoc      = true
end
