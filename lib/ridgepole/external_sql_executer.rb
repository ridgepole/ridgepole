class Ridgepole::ExternalSqlExecuter
  def initialize(script, logger)
    @script = script
    @logger = logger
  end

  def execute(sql)
    cmd = Shellwords.join([@script, sql, JSON.dump(ActiveRecord::Base.connection_config)])
    @logger.info("Execute #{@script}")

    out, err, status = Open3.capture3(cmd)
    out.strip!
    err.strip!

    @logger.info("#{@script}: #{out}") unless out.empty?
    @logger.warn("[WARNING] #{@script}: #{err}") unless err.empty?

    unless status.success?
      raise "`#{@script}` execution failed"
    end
  end
end
