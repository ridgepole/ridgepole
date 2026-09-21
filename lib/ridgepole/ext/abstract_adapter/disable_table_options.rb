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

          if @__without_table_options
            # NOTE: Since Rails 8.2, `table_options` also accepts an array of table names
            #       and then returns a hash of options keyed by table name.
            if table_name.is_a?(Array)
              options.each_value { |table_option| delete_table_options!(table_option) }
            else
              delete_table_options!(options)
            end
          end

          options
        end

        private

        def delete_table_options!(options)
          return unless options

          options.delete(:options)
          options.delete(:charset)
          options.delete(:collation)
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
        super
      end
    end
  end
end
