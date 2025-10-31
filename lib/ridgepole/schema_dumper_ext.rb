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

module Ridgepole
  module SchemaDumperDisableSortColumnsExt
    def table(table, stream)
      def @connection.columns(*_args)
        cols = super
        def cols.sort_by(*_args, &_block)
          self
        end
        cols
      end
      super
    end
  end
end

module ActiveRecord
  class SchemaDumper
    prepend Ridgepole::SchemaDumperExt
  end
end
