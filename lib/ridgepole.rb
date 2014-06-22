require 'logger'
require 'singleton'
require 'stringio'

require 'active_record'
require 'activerecord-mysql-unsigned'

module Ridgepole; end
require 'ridgepole/client'
require 'ridgepole/delta'
require 'ridgepole/diff'
require 'ridgepole/dsl_parser'
require 'ridgepole/dumper'
require 'ridgepole/logger'
require 'ridgepole/string_ext'
require 'ridgepole/version'
