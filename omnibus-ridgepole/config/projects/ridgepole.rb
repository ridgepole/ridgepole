require 'json'
require 'open-uri'

name 'ridgepole'
maintainer 'winebarrel <sugawara@winebarrel.jp>'
homepage 'https://github.com/winebarrel/ridgepole'

# Defaults to C:/ridgepole on Windows
# and /opt/ridgepole on all other platforms
install_dir "#{default_root}/#{name}"

build_version JSON.parse(open('https://rubygems.org/api/v1/gems/ridgepole.json', &:read)).fetch('version')
build_iteration 1

dependency 'preparation'

# ridgepole dependencies/components
override :ruby, version: '2.5.1'
dependency 'ruby'
dependency 'rubygems'
dependency 'ridgepole'

# Version manifest file
dependency 'version-manifest'

exclude '**/.git'
exclude '**/bundler/git'
