# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PartitionDefinition
      attr_reader :name, :values

      def initialize(
        name,
        values
      )
        @name = name
        @values = values
      end
    end
  end
end
