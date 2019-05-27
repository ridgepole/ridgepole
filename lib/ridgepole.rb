# frozen_string_literal: true

require 'logger'
require 'open3'
require 'pp'
require 'shellwords'
require 'singleton'
require 'stringio'

require 'active_record'
require 'active_support'
require 'active_support/core_ext'

require 'diffy'

module Ridgepole; end

require 'ridgepole/ext/abstract_adapter/disable_table_options'
require 'ridgepole/ext/pp_sort_hash'
require 'ridgepole/ext/schema_dumper'
require 'ridgepole/client'
require 'ridgepole/connection_adapters'
require 'ridgepole/default_limit'
require 'ridgepole/delta'
require 'ridgepole/diff'
require 'ridgepole/dsl_parser'
require 'ridgepole/dsl_parser/context'
require 'ridgepole/dsl_parser/table_definition'
require 'ridgepole/dumper'
require 'ridgepole/execute_expander'
require 'ridgepole/external_sql_executer'
require 'ridgepole/logger'
require 'ridgepole/migration_ext'
require 'ridgepole/schema_dumper_ext'
require 'ridgepole/schema_statements_ext'
require 'ridgepole/version'
