# frozen_string_literal: true

require 'active_record/schema_dumper'

module Ridgepole
  module Ext
    module SchemaDumper
      module DisableSortColumns
        def table(table, stream)
          def @connection.columns(*_args)
            cols = super
            def cols.sort_by(*_args, &_block)
              self
            end
            cols
          end
          super
        end
      end
    end
  end
end

module ActiveRecord
  class SchemaDumper
    prepend Ridgepole::Ext::SchemaDumper::DisableSortColumns
  end
end
