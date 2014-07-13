require 'logger'
require 'singleton'
require 'stringio'

require 'active_record'
require 'active_support'

module Ridgepole; end
require 'ridgepole/client'
require 'ridgepole/delta'
require 'ridgepole/diff'
require 'ridgepole/dsl_parser'
require 'ridgepole/dumper'
require 'ridgepole/logger'
require 'ridgepole/migration_ext'
require 'ridgepole/schema_dumper_ext'
require 'ridgepole/version'
