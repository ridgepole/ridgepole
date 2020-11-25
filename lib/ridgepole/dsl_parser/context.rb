# frozen_string_literal: true

module Ridgepole
  class DSLParser
    class Context
      attr_reader :__definition, :__execute

      def initialize(opts = {})
        @__working_dir = File.expand_path(opts[:path] ? File.dirname(opts[:path]) : Dir.pwd)
        @__definition = {}
        @__execute = []
      end

      def self.eval(dsl, opts = {})
        ctx = new(opts)

        if opts[:path]
          ctx.instance_eval(dsl, opts[:path])
        else
          ctx.instance_eval(dsl)
        end

        [ctx.__definition, ctx.__execute]
      end

      def create_table(table_name, options = {})
        table_name = table_name.to_s
        table_definition = TableDefinition.new(table_name, self)

        options[:primary_key] = options[:primary_key].to_s if options[:primary_key].is_a?(Symbol)
        if options[:id] && TableDefinition::ALIAS_TYPES.key?(options[:id])
          type, type_default_opts = TableDefinition::ALIAS_TYPES[options[:id]]
          options[:id] = type
          options = type_default_opts.merge(options)
        end

        yield(table_definition)
        @__definition[table_name] ||= {}

        raise "Table `#{table_name}` already defined" if @__definition[table_name][:definition]

        @__definition[table_name][:definition] = table_definition.__definition
        options.delete(:force)
        @__definition[table_name][:options] = options
      end

      def add_index(table_name, column_name, options = {})
        table_name = table_name.to_s
        # Keep column_name for expression index support
        # https://github.com/rails/rails/pull/23393
        column_name = [column_name].flatten.map(&:to_s) unless column_name.is_a?(String) && /\W/ === column_name # rubocop:disable Style/CaseEquality
        options[:name] = options[:name].to_s if options[:name]
        @__definition[table_name] ||= {}
        @__definition[table_name][:indices] ||= {}
        idx = options[:name] || column_name

        raise "Index `#{table_name}(#{idx})` already defined" if @__definition[table_name][:indices][idx]

        if options[:length].is_a?(Numeric)
          index_length = options[:length]
          options[:length] = {}

          column_name.each do |col|
            options[:length][col] = index_length
          end
        end

        options[:length] = options[:length].compact.symbolize_keys if options[:length]

        @__definition[table_name][:indices][idx] = {
          column_name: column_name,
          options: options,
        }
      end

      def add_foreign_key(from_table, to_table, options = {})
        from_table = from_table.to_s
        to_table = to_table.to_s
        options[:name] = options[:name].to_s if options[:name]
        options[:primary_key] = options[:primary_key].to_s if options[:primary_key]
        options[:column] = options[:column].to_s if options[:column]
        @__definition[from_table] ||= {}
        @__definition[from_table][:foreign_keys] ||= {}
        idx = options[:name] || [from_table, to_table, options[:column]]

        raise "Foreign Key `#{from_table}(#{idx})` already defined" if @__definition[from_table][:foreign_keys][idx]

        @__definition[from_table][:foreign_keys][idx] = {
          to_table: to_table,
          options: options,
        }
      end

      def require(file)
        schemafile = %r{\A/}.match?(file) ? file : File.join(@__working_dir, file)

        if File.exist?(schemafile)
          instance_eval(File.read(schemafile), schemafile)
        elsif File.exist?(schemafile + '.rb')
          instance_eval(File.read(schemafile + '.rb'), schemafile + '.rb')
        else
          Kernel.require(file)
        end
      end

      def require_relative(relative_path)
        require(File.expand_path(relative_path, File.dirname(caller[0])))
      end

      def execute(sql, _name = nil, &cond)
        @__execute << {
          sql: sql,
          condition: cond,
        }
      end
    end
  end
end
