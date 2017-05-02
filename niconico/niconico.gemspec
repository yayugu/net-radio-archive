# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "niconico/version"

Gem::Specification.new do |s|
  s.name        = "niconico"
  s.version     = Niconico::VERSION
  s.authors     = ["Shota Fukumori (sora_h)"]
  s.email       = ["her@sorah.jp"]
  s.homepage    = ""
  s.summary     = "wrapper of Mechanize, optimized for nicovideo."
  s.description = "wrapper of Mechanize, optimized for nicovideo. :)"

  s.add_dependency "mechanize", '>= 2.7.3'
  s.add_dependency "nokogiri", '>= 1.6.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
