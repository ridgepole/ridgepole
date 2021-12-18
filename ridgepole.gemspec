# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ridgepole/version'

Gem::Specification.new do |spec|
  spec.name          = 'ridgepole'
  spec.version       = Ridgepole::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@winebarrel.jp']
  spec.summary       = 'Ridgepole is a tool to manage DB schema.'
  spec.description   = 'Ridgepole is a tool to manage DB schema. It defines DB schema using Rails DSL, and updates DB schema according to DSL.'
  spec.homepage      = 'https://github.com/ridgepole/ridgepole'
  spec.license       = 'MIT'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 2.2.7') # rubocop:disable Gemspec/RequiredRubyVersion

  spec.add_dependency 'activerecord', '>= 5.1', '< 7.1'
  spec.add_dependency 'diffy'

  spec.add_development_dependency 'appraisal', '>= 2.2.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'erbh', '>= 0.1.2'
  spec.add_development_dependency 'hash_modern_inspect', '>= 0.1.1'
  spec.add_development_dependency 'hash_order_helper', '>= 0.1.6'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'rspec-match_fuzzy', '>= 0.1.3'
  spec.add_development_dependency 'rspec-match_ruby', '>= 0.1.3'
  spec.add_development_dependency 'rubocop', '1.9.1'
  spec.add_development_dependency 'rubocop-rake', '>= 0.5.1'
  spec.add_development_dependency 'rubocop-rspec', '>= 2.1.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-lcov'
end
