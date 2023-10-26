# frozen_string_literal: true

module Ridgepole
  class DefaultsLimit
    DEFAULT_LIMIT_FOR_MYSQL = {
      boolean: 1,
      integer: 4,
      bigint: 8,
      float: 24,
      string: 255,
      text: 65_535,
      binary: 65_535,
    }.freeze

    DEFAULTS_LIMITS = {
      mysql2: DEFAULT_LIMIT_FOR_MYSQL,
      trilogy: DEFAULT_LIMIT_FOR_MYSQL,
    }.freeze

    class << self
      def default_limit(column_type, options)
        defaults = DEFAULTS_LIMITS[adapter] || {}
        option_key = :"default_#{column_type}_limit"
        default_limit = options[option_key] || defaults[column_type] || 0
        default_limit.zero? ? nil : default_limit
      end

      def adapter
        ActiveRecord::Base.connection.adapter_name.downcase.to_sym
      rescue ActiveRecord::ConnectionNotEstablished
        nil
      end
    end
  end
end
