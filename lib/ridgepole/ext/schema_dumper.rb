# frozen_string_literal: true

require 'active_record/schema_dumper'

module Ridgepole
  module Ext
    module SchemaDumper
      def self.prepended(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        attr_reader :__with_default_fk_name

        def with_default_fk_name(value)
          @__with_default_fk_name = value
          yield
        ensure
          remove_instance_variable(:@__with_default_fk_name)
        end
      end

      def foreign_keys(table, stream)
        return super unless ActiveRecord::SchemaDumper.__with_default_fk_name

        if (foreign_keys = @connection.foreign_keys(table)).any?
          add_foreign_key_statements = foreign_keys.map do |foreign_key|
            parts = [
              "add_foreign_key #{remove_prefix_and_suffix(foreign_key.from_table).inspect}",
              remove_prefix_and_suffix(foreign_key.to_table).inspect
            ]

            parts << "column: #{foreign_key.column.inspect}" if foreign_key.column != @connection.foreign_key_column_for(foreign_key.to_table)

            parts << "primary_key: #{foreign_key.primary_key.inspect}" if foreign_key.custom_primary_key?

            parts << "name: #{foreign_key.name.inspect}"

            parts << "on_update: #{foreign_key.on_update.inspect}" if foreign_key.on_update
            parts << "on_delete: #{foreign_key.on_delete.inspect}" if foreign_key.on_delete

            "  #{parts.join(', ')}"
          end

          stream.puts add_foreign_key_statements.sort.join("\n")
        end
      end

      def tables(stream)
        original = ignore_tables.dup
        ignore_tables.concat(@connection.partition_tables)
        super
      ensure
        self.ignore_tables = original
      end

      def table(table, stream)
        super
        partition(table, stream)
      end

      def partition(table, stream)
        if (partition = @connection.partition(table))
          partition_definitions = partition.partition_definitions.map do |partition_definition|
            "{ name: #{partition_definition.name.inspect}, values: #{partition_definition.values} }"
          end.join(' ,')

          stream.puts "  add_partition #{partition.table.inspect}, #{partition.type.inspect}, #{partition.columns.inspect}, partition_definitions: [#{partition_definitions}]"
          stream.puts
        end
      end
    end
  end
end

module ActiveRecord
  class SchemaDumper
    prepend Ridgepole::Ext::SchemaDumper
  end
end
