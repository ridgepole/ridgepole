class Ridgepole::ExternalSqlExecuter
  def initialize(script, logger)
    @script = script
    @logger = logger
  end

  def execute(sql)
    cmd = Shellwords.join([@script, sql, JSON.dump(ActiveRecord::Base.connection_config)])
    @logger.info("Execute #{@script}")
    script_basename = File.basename(@script)

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close_write

      begin
        loop do
          IO.select([stdout, stderr]).flatten.compact.each do |io|
            io.each do |line|
              next if line.nil?
              line.strip!

              if io == stderr
                @logger.warn("[WARNING] #{script_basename}: #{line}")
              else
                @logger.info("#{script_basename}: #{line}")
              end
            end
          end

          if stdout.eof? and stderr.eof?
            break
          end
        end
      rescue EOFError
      end

      unless wait_thr.value.success?
        raise "`#{@script}` execution failed"
      end
    end
  end
end
