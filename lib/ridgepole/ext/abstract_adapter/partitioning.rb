# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module Ridgepole
  module Ext
    module AbstractAdapter
      module Partitioning
        def partition(*)
          nil
        end

        def partition_tables
          []
        end

        # SchemaStatements
        def create_partition(*)
          raise NotImplementedError
        end

        def add_partition(*)
          raise NotImplementedError
        end

        def remove_partition(*)
          raise NotImplementedError
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      prepend Ridgepole::Ext::AbstractAdapter::Partitioning
    end
  end
end
