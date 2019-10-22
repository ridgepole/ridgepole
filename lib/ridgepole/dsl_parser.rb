# frozen_string_literal: true

module Ridgepole
  class DSLParser
    def initialize(options = {})
      @options = options
    end

    def parse(dsl, opts = {})
      definition, execute = Context.eval(dsl, opts)
      check_definition(definition)
      [definition, execute]
    end

    private

    def check_definition(definition)
      definition.each do |table_name, attrs|
        check_orphan_index(table_name, attrs)
        check_orphan_foreign_key(table_name, attrs)
        check_foreign_key_without_index(table_name, attrs)
      end
    end

    def check_orphan_index(table_name, attrs)
      raise "Table `#{table_name}` to create the index is not defined: #{attrs[:indices].keys.join(',')}" if attrs[:indices] && !(attrs[:definition])
    end

    def check_orphan_foreign_key(table_name, attrs)
      raise "Table `#{table_name}` to create the foreign key is not defined: #{attrs[:foreign_keys].keys.join(',')}" if attrs[:foreign_keys] && !(attrs[:definition])
    end

    def check_foreign_key_without_index(table_name, attrs)
      return unless attrs[:foreign_keys]
      return unless attrs[:options][:options]&.include?('ENGINE=InnoDB')

      attrs[:foreign_keys].each do |_, foreign_key_attrs|
        fk_index = foreign_key_attrs[:options][:column] || "#{foreign_key_attrs[:to_table].singularize}_id"
        next if attrs[:indices]&.any? { |_k, v| v[:column_name].first == fk_index }

        Ridgepole::Logger.instance.warn(<<-MSG)
[WARNING] Table `#{table_name}` has a foreign key on `#{fk_index}` column, but doesn't have any indexes on the column.
          Although an index will be added automatically by InnoDB, please add an index explicitly for your future operations.
        MSG
      end
    end
  end
end
