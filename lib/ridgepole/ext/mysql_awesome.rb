require 'active_record/connection_adapters/abstract/schema_definitions'

# XXX: https://github.com/waka/activerecord-mysql-unsigned/blob/v0.3.1/lib/activerecord-mysql-unsigned/active_record/v3/connection_adapters/abstract/schema_definitions.rb#L14
class ActiveRecord::ConnectionAdapters::TableDefinition
  def primary_key(name, type = :primary_key, options = {})
    column(name, type, options.merge(primary_key: true).reverse_merge(unsigned: true))
  end
end
