# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_mysql_adapter'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module DumpAutoIncrement
        def prepare_column_options(column)
          spec = super
          spec[:auto_increment] = 'true' if column.auto_increment?
          spec
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      prepend Ridgepole::Ext::AbstractMysqlAdapter::DumpAutoIncrement
    end
  end
end
