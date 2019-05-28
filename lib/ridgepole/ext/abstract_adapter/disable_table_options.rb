# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module Ridgepole
  module Ext
    module AbstractAdapter
      module DisableTableOptions
        def without_table_options(value)
          @__without_table_options = value
          yield
        ensure
          remove_instance_variable(:@__without_table_options)
        end

        def table_options(table_name)
          options = super
          options.delete(:options) if options && @__without_table_options
          options
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def self.inherited(subclass)
        subclass.prepend Ridgepole::Ext::AbstractAdapter::DisableTableOptions
      end
    end
  end
end
