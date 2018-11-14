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
    end
  end
end

module ActiveRecord
  class SchemaDumper
    prepend Ridgepole::Ext::SchemaDumper
  end
end
