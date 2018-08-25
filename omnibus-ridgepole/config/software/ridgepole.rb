require 'json'
require 'open-uri'

name 'ridgepole'

default_version JSON.parse(open('https://rubygems.org/api/v1/gems/ridgepole.json', &:read)).fetch('version')

license 'MIT'
skip_transitive_dependency_licensing true

build do
  gem 'install ridgepole -N'
end
