# XXX: https://github.com/waka/activerecord-mysql-unsigned/blob/v0.3.1/lib/activerecord-mysql-unsigned/active_record/v3/connection_adapters/abstract/schema_definitions.rb#L14
class ActiveRecord::ConnectionAdapters::TableDefinition
  alias primary_key_without_unsigned primary_key

  def primary_key(name, type = :primary_key, options = {})
    primary_key_without_unsigned(name, type, options.merge(primary_key: true).reverse_merge(unsigned: true))
  end
end
