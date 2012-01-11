# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "io_unblock/version"

Gem::Specification.new do |s|
  s.name        = "io_unblock"
  s.version     = IoUnblock::VERSION
  s.authors     = ["Ian D. Eccles"]
  s.email       = ["ian.eccles@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "io_unblock"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
end
