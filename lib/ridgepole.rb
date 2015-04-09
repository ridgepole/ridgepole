require 'logger'
require 'singleton'
require 'stringio'

require 'active_record'
require 'active_support'
require 'active_support/core_ext'

module Ridgepole
  # for MySQL
  DEFAULTS_LIMITS = {
    :boolean => 1,
    :integer => 4,
    :float   => 24,
    :string  => 255,
    :text    => 65535,
  }
end

require 'ridgepole/client'
require 'ridgepole/delta'
require 'ridgepole/diff'
require 'ridgepole/dsl_parser'
require 'ridgepole/dumper'
require 'ridgepole/execute_expander'
require 'ridgepole/logger'
require 'ridgepole/migration_ext'
require 'ridgepole/schema_dumper_ext'
require 'ridgepole/version'
