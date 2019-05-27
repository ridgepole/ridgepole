# frozen_string_literal: true

module Ridgepole
  class Logger < ::Logger
    include Singleton
    cattr_accessor :verbose

    def initialize
      super($stdout)

      self.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end

      self.level = Logger::INFO
    end

    def verbose_info(msg)
      info(msg) if verbose
    end

    def debug=(value)
      self.level = value ? Logger::DEBUG : Logger::INFO
    end
  end
end
