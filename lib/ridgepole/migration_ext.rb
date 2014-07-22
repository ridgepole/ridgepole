require 'active_record/migration'

class ActiveRecord::Migration
  cattr_accessor :time_recorder
  cattr_accessor :disable_logging

  def write_with_logging(text = '')
    logger = Ridgepole::Logger.instance
    logger.info(text) unless self.disable_logging
    parse_text(text)
  end
  alias_method_chain :write, :logging

  def parse_text(text)
    return unless self.time_recorder

    case text
    when /\A--\s+(.+)\Z/
      self.time_recorder.add_key($1)
    when /\A\s+->\s+(\d+\.\d+)s\Z/
      self.time_recorder.add_value($1.to_f)
    end
  end

  def self.record_time
    result = nil

    begin
      self.time_recorder = TimeRecorder.new
      yield
      result = self.time_recorder.result
    ensure
      self.time_recorder = nil
    end

    return result
  end

  class TimeRecorder
    attr_reader :result

    def initialize
      @result = {}
    end

    def add_key(key)
      @key = key
    end

    def add_value(value)
      if @key
        @result[@key] = value
      end

      @key = nil
    end
  end
end
