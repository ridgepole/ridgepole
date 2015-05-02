class Ridgepole::DefaultsLimit
  DEFAULTS_LIMITS = {
    :mysql2 => {
      :boolean => 1,
      :integer => 4,
      :float   => 24,
      :string  => 255,
      :text    => 65535,
      :binary  => 65535,
    }
  }

  class << self
    def default_limit(column_type, options)
      defaults = DEFAULTS_LIMITS[adapter] || {}
      option_key = :"default_#{column_type}_limit"
      default_limit = options[option_key] || defaults[column_type] || 0
      default_limit.zero? ? nil : default_limit
    end

    def adapter
      ActiveRecord::Base.connection_config.fetch(:adapter).to_sym
    rescue ActiveRecord::ConnectionNotEstablished
      nil
    end
  end # of class methods
end
