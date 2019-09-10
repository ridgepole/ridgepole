# frozen_string_literal: true

require 'tsort'

module Ridgepole
  class DSLParser
    def initialize(options = {})
      @options = options
    end

    def parse(dsl, opts = {})
      definition, execute = Context.eval(dsl, opts)
      check_orphan_index(definition)
      check_orphan_foreign_key(definition)
      sorted_definition = {}
      DependencyGraph.new(definition).tsort_each do |table_name|
        sorted_definition[table_name] = definition[table_name]
      end
      [sorted_definition, execute]
    end

    private

    def check_orphan_index(definition)
      definition.each do |table_name, attrs|
        raise "Table `#{table_name}` to create the index is not defined: #{attrs[:indices].keys.join(',')}" if attrs[:indices] && !(attrs[:definition])
      end
    end

    def check_orphan_foreign_key(definition)
      definition.each do |table_name, attrs|
        raise "Table `#{table_name}` to create the foreign key is not defined: #{attrs[:foreign_keys].keys.join(',')}" if attrs[:foreign_keys] && !(attrs[:definition])
      end
    end

    class DependencyGraph
      include TSort

      def initialize(definition)
        @definition = definition
      end

      def tsort_each_child(table_name, &block)
        keys = @definition[table_name].fetch(:foreign_keys, {})
        keys.each_value { |v| block.call(v[:to_table]) }
      end

      def tsort_each_node(&block)
        @definition.each_key(&block)
      end
    end
  end
end
