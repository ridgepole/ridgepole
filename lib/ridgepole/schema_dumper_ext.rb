# frozen_string_literal: true

require 'active_record/schema_dumper'

module Ridgepole
  module SchemaDumperExt
    def table(table, stream)
      logger = Ridgepole::Logger.instance
      logger.verbose_info("#   #{table}")
      super
    end
  end
end

module ActiveRecord
  class SchemaDumper
    prepend Ridgepole::SchemaDumperExt
  end
end
