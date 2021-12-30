# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PartitionOptions
      attr_reader :table, :type, :columns, :partition_definitions

      TYPES = %i[range list].freeze

      def initialize(
        table, type,
        columns,
        partition_definitions: []
      )
        @table = table
        @type = type
        @columns = Array.wrap(columns)
        @partition_definitions = build_definitions(partition_definitions)
      end

      private

      def build_definitions(definitions)
        definitions.map do |definition|
          next if definition.is_a?(PartitionDefinition)

          PartitionDefinition.new(definition.fetch(:name), definition.fetch(:values))
        end.compact
      end
    end
  end
end
