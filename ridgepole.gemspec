# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ridgepole/version'

Gem::Specification.new do |spec|
  spec.name          = 'ridgepole'
  spec.version       = Ridgepole::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@cookpad.com']
  spec.summary       = %q{Ridgepole is a tool to manage DB schema.}
  spec.description   = %q{Ridgepole is a tool to manage DB schema. It defines DB schema using Rails DSL, and updates DB schema according to DSL.}
  spec.homepage      = 'https://github.com/winebarrel/ridgepole'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.2', '< 6'
  spec.add_dependency 'diffy'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'mysql2', '~> 0.3.20'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'rspec-match_fuzzy', '>= 0.1.3'
  spec.add_development_dependency 'erbh', '>= 0.1.2'
  spec.add_development_dependency 'hash_modern_inspect', '>= 0.1.1'
  spec.add_development_dependency 'hash_order_helper', '>= 0.1.5'
end
