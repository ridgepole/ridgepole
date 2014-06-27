require 'active_record/migration'

class ActiveRecord::Migration
  def write_with_logging(text = '')
    logger = Ridgepole::Logger.instance
    logger.info(text)
  end
  alias_method_chain :write, :logging
end
