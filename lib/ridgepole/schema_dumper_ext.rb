require 'active_record/schema_dumper'

class ActiveRecord::SchemaDumper
  def table_with_logging(table, stream)
    logger = Ridgepole::Logger.instance
    logger.verbose_info("#   #{table}")
    table_without_logging(table, stream)
  end
  alias_method_chain :table, :logging
end
