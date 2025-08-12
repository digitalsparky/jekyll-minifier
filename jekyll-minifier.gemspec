# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jekyll-minifier/version', __FILE__)

Gem::Specification.new do |gem|
  gem.specification_version = 2 if gem.respond_to? :specification_version=
  gem.required_rubygems_version = Gem::Requirement.new('>= 0') if gem.respond_to? :required_rubygems_version=
  gem.required_ruby_version = '>= 3.0.0'

  gem.authors     = ["DigitalSparky"]
  gem.email       = ["matthew@spurrier.com.au"]
  gem.description = %q{Jekyll Minifier using htmlcompressor for html, terser for js, and cssminify2 for css}
  gem.summary     = %q{Jekyll Minifier for html, css, and javascript}
  gem.homepage    = "http://github.com/digitalsparky/jekyll-minifier"
  gem.license     = "GPL-3.0-or-later"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "jekyll-minifier"
  gem.require_paths = ["lib"]

  if ENV['TRAVIS_TAG']
    gem.version     = "#{ENV['TRAVIS_TAG']}"
  else
    gem.version     = Jekyll::Minifier::VERSION
  end

  gem.add_dependency "jekyll", "~> 4.0"
  gem.add_dependency "terser", "~> 1.2.3"
  gem.add_dependency "htmlcompressor", "~> 0.4"
  gem.add_dependency "cssminify2", "~> 2.1.0"
  gem.add_dependency "json-minify", "~> 0.0.3"

  gem.add_development_dependency "rake", "~> 13.3"
  gem.add_development_dependency "rspec", "~> 3.13"
  gem.add_development_dependency "jekyll-paginate", "~> 1.1"
  gem.add_development_dependency "redcarpet", "~> 3.4"
  gem.add_development_dependency "rss", "~> 0.3"
end
