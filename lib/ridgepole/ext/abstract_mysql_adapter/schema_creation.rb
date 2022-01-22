# frozen_string_literal: true

require 'active_record/connection_adapters/mysql/schema_creation'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module SchemaCreation
        def visit_PartitionOptions(o)
          sqls = o.partition_definitions.map { |partition_definition| accept partition_definition }
          function = case o.type
                     when :list
                       "LIST COLUMNS(#{o.columns.map { |column| quote_column_name(column) }.join(',')})"
                     when :range
                       "RANGE COLUMNS(#{o.columns.map { |column| quote_column_name(column) }.join(',')})"
                     else
                       raise NotImplementedError
                     end
          "ALTER TABLE #{quote_table_name(o.table)} PARTITION BY #{function} (#{sqls.join(',')})"
        end

        def visit_PartitionDefinition(o)
          if o.values.key?(:in)
            "PARTITION #{o.name} VALUES IN (#{o.values[:in].map do |value|
              value.is_a?(Array) ? "(#{value.map(&:inspect).join(',')})" : value.inspect
            end.join(',')})"
          elsif o.values.key?(:to)
            "PARTITION #{o.name} VALUES LESS THAN (#{o.values[:to].map(&:inspect).join(',')})"
          else
            raise NotImplementedError
          end
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module MySQL
      class SchemaCreation
        prepend Ridgepole::Ext::AbstractMysqlAdapter::SchemaCreation
      end
    end
  end
end
