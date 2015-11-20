require 'active_record/connection_adapters/abstract_mysql_adapter'

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  def add_index_with_alter(table_name, column_name, options = {})
    index_name, index_type, index_columns, index_options, index_algorithm, index_using = add_index_options(table_name, column_name, options)

    # cannot specify index_algorithm
    execute "ALTER TABLE #{quote_table_name(table_name)} ADD INDEX #{quote_column_name(index_name)} #{index_type} #{index_using} (#{index_columns})#{index_options}"
  end
  alias_method_chain :add_index, :alter

  def remove_index_with_alter!(table_name, index_name)
    execute "ALTER TABLE #{quote_table_name(table_name)} DROP INDEX #{quote_column_name(index_name)}"
  end
  alias_method_chain :remove_index!, :alter
end
