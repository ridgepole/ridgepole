require 'active_record/migration'

module Ridgepole
  module MigrationExt
    def self.prepended(klass)
      klass.class_eval do
        cattr_accessor :time_recorder
        cattr_accessor :disable_logging

        def self.record_time
          result = nil

          begin
            self.time_recorder = TimeRecorder.new
            yield
            result = time_recorder.result
          ensure
            self.time_recorder = nil
          end

          result
        end
      end
    end

    def write(text = '')
      logger = Ridgepole::Logger.instance
      logger.info(text) unless disable_logging
      parse_text(text)
    end

    def parse_text(text)
      return unless time_recorder

      case text
      when /\A--\s+(.+)\Z/
        time_recorder.add_key(Regexp.last_match(1))
      when /\A\s+->\s+(\d+\.\d+)s\Z/
        time_recorder.add_value(Regexp.last_match(1).to_f)
      end
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
        @result[@key] = value if @key

        @key = nil
      end
    end
  end
end

module ActiveRecord
  class Migration
    prepend Ridgepole::MigrationExt
  end
end
