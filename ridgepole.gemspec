# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ridgepole/version'

Gem::Specification.new do |spec|
  spec.name          = 'ridgepole'
  spec.version       = Ridgepole::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@cookpad.com']
  spec.summary       = %q{Ridgepole is a tool to DB schema.}
  spec.description   = %q{Ridgepole is a tool to DB schema. It defines DB schema using Rails DSL, and updates DB schema according to DSL.}
  spec.homepage      = 'https://bitbucket.org/winebarrel/ridgepole'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'activerecord-mysql-unsigned', '>= 0.1.3'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.14.1'
  spec.add_development_dependency 'mysql2'
end
