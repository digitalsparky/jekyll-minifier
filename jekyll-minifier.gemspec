# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jekyll-minifier/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors     = ["DigitalSparky"]
  gem.email       = ["matthew@spurrier.com.au"]
  gem.description = %q{Jekyll Minifier using htmlcompressor for html , and YUI compressor for js and css}
  gem.summary     = %q{Jekyll Minifier for html, css, and javascript}
  gem.homepage    = "http://github.com/digitalsparky/jekyll-minifier"
  gem.license     = "GPLv3"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "jekyll-minifier"
  gem.require_paths = ["lib"]
  gem.version       = Jekyll::Minifier::VERSION

  gem.add_dependency "jekyll", "~> 2.5", ">= 2.5.3"
  gem.add_dependency "yui-compressor", "~> 0.12", ">= 0.12.0"
  gem.add_dependency "htmlcompressor", "~> 0.1.2", ">= 0.1.2"

  gem.add_development_dependency "rake"
end
