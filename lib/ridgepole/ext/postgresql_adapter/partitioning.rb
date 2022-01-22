# frozen_string_literal: true

require 'active_record/connection_adapters/postgresql_adapter'

module Ridgepole
  module Ext
    module PostgreSQLAdapter
      module Partitioning
        def supports_partitions?
          ActiveRecord::VERSION::MAJOR >= 6 && postgresql_version >= 100_000 # >= 10.0
        end

        def table_options(table_name)
          options = partition_options(table_name)
          if options
            (super || {}).merge(options: "PARTITION BY #{options[:type].to_s.upcase}(#{options[:columns].join(',')})")
          else
            super
          end
        end

        def partition_options(table_name)
          return unless supports_partitions?

          scope = quoted_scope(table_name)
          result = query_value(<<~SQL, 'SCHEMA')
            SELECT pg_get_partkeydef(t.oid)
            FROM pg_class t
              LEFT JOIN pg_namespace n ON n.oid = t.relnamespace
            WHERE t.relname = #{scope[:name]}
              AND n.nspname = #{scope[:schema]}
          SQL
          return unless result

          type, *columns = result.scan(/\w+/).map { |value| value.downcase.to_sym }
          { type: type, columns: columns }
        end

        def partition(table_name)
          options = partition_options(table_name)
          return unless options

          scope = quoted_scope(table_name)
          partition_info = query(<<~SQL, 'SCHEMA')
            SELECT p.relname, pg_get_expr(p.relpartbound, p.oid, true)
            FROM pg_class t
            JOIN pg_inherits i on i.inhparent = t.oid
            JOIN pg_class p on p.oid = i.inhrelid
            WHERE t.relname = #{scope[:name]}
              AND p.relnamespace::regnamespace::text = #{scope[:schema]}
            ORDER BY p.relname
          SQL

          partition_definitions = partition_info.map do |row|
            values = case options[:type]
                     when :list
                       values = row[1].match(/FOR VALUES IN \((?<csv>.+)\)$/)[:csv].split(',').map(&:strip).map { |value| cast_value(value) }
                       { in: Array.wrap(values) }
                     when :range
                       match = row[1].match(/FOR VALUES FROM \((?<from>.+)\) TO \((?<to>.+)\)/)
                       from = match[:from].split(',').map(&:strip).map { |value| cast_value(value) }
                       to = match[:to].split(',').map(&:strip).map { |value| cast_value(value) }
                       { from: from, to: to }
                     else
                       raise NotImplementedError
                     end
            { name: row[0], values: values }
          end

          ActiveRecord::ConnectionAdapters::PartitionOptions.new(table_name, options[:type], options[:columns], partition_definitions: partition_definitions)
        end

        def cast_value(value)
          Integer(value)
        rescue ArgumentError
          value.delete(%q("')) # "
        end

        def quote_value(value)
          if %w[MINVALUE MAXVALUE].include?(value)
            value
          else
            quote(value)
          end
        end

        def partition_tables
          partition_info = query(<<~SQL, 'SCHEMA')
            SELECT p.relname
            FROM pg_class t
            JOIN pg_inherits i on i.inhparent = t.oid
            JOIN pg_class p on p.oid = i.inhrelid
            ORDER BY p.relname
          SQL
          partition_info.map { |row| row[0] }
        end

        # SchemaStatements
        def add_partition(table_name, name:, values:)
          condition = if values.key?(:in)
                        "FOR VALUES IN (#{values[:in].map { |v| quote_value(v) }.join(',')})"
                      elsif values.key?(:to)
                        from = values[:from].map { |v| quote_value(v) }.join(',')
                        to = values[:to].map { |v| quote_value(v) }.join(',')
                        "FOR VALUES FROM (#{from}) TO (#{to})"
                      else
                        raise NotImplementedError
                      end
          create_table(name, id: false, options: "PARTITION OF #{table_name} #{condition}")
        end

        def remove_partition(_table_name, name:)
          drop_table(name)
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      prepend Ridgepole::Ext::PostgreSQLAdapter::Partitioning
    end
  end
end
