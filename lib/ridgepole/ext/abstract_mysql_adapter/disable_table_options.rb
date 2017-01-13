require 'active_record/connection_adapters/abstract_mysql_adapter'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module DisableTableOptions
        def table_options(table_name)
          options = super
          options.delete(:options)
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
