require 'active_record/connection_adapters/abstract_mysql_adapter'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module DisableTableOptions
        def without_table_options(value)
          prev_value = @__without_table_options
          @__without_table_options = value
          yield
        ensure
          @__without_table_options = prev_value
        end

        def table_options(table_name)
          options = super
          options.delete(:options) if @__without_table_options
          options
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      prepend Ridgepole::Ext::AbstractMysqlAdapter::DisableTableOptions
    end
  end
end
