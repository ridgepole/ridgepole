# frozen_string_literal: true

module Ridgepole
  class ExternalSqlExecuter
    def initialize(script, logger)
      @script = script
      @logger = logger
    end

    def execute(sql)
      cmd = Shellwords.join([@script, sql, JSON.dump(connection_configuration_hash)])
      @logger.info("Execute #{@script}")
      script_basename = File.basename(@script)

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write
        files = [stdout, stderr]

        begin
          until files.empty?
            ready = IO.select(files)

            next unless ready

            readable = ready[0]

            readable.each do |f|
              data = f.read_nonblock(1024)
              next if data.nil?

              data.chomp!

              if f == stderr
                @logger.warn("[WARNING] #{script_basename}: #{data}")
              else
                @logger.info("#{script_basename}: #{data}")
              end
            rescue EOFError
              files.delete f
            end
          end
        rescue EOFError
          # nothing to do
        end

        raise "`#{@script}` execution failed" unless wait_thr.value.success?
      end
    end

    private

    def connection_configuration_hash
      if ActiveRecord.gem_version < Gem::Version.new('6.1.0')
        # NOTE: Remove code when stopping support for versions below 6.1
        ActiveRecord::Base.connection_config
      else
        ActiveRecord::Base.connection_db_config.configuration_hash
      end
    end
  end
end
