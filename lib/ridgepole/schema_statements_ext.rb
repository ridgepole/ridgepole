require 'active_record/connection_adapters/abstract/schema_statements'

module ActiveRecord::ConnectionAdapters::SchemaStatements
  def rename_table_indexes_with_ignore(table_name, new_name)
    # Nothing to do
  end

  alias_method_chain :rename_table_indexes, :ignore
end
