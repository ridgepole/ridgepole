require 'erb'
require 'yaml'

class Ridgepole::Config
  class << self
    def load(config, env = 'development')
      config = ENV.fetch(Regexp.last_match(1)) if config =~ /\Aenv:(.+)\z/

      parsed_config = if File.exist?(config)
                        parse_config_file(config)
                      elsif (expanded = File.expand_path(config)) && File.exist?(expanded)
                        parse_config_file(expanded)
                      else
                        YAML.safe_load(ERB.new(config).result, [], [], true)
                      end

      unless parsed_config.is_a?(Hash)
        parsed_config = parse_database_url(config)
      end

      if parsed_config.key?(env.to_s)
        parsed_config.fetch(env.to_s)
      else
        parsed_config
      end
    end

    private

    def parse_config_file(path)
      yaml = ERB.new(File.read(path)).result
      YAML.safe_load(yaml, [], [], true)
    end

    def parse_database_url(config)
      uri = URI.parse(config)

      if [uri.scheme, uri.user, uri.host, uri.path].any? { |i| i.nil? || i.empty? }
        raise "Invalid config: #{config.inspect}"
      end

      {
        'adapter'  => uri.scheme,
        'username' => uri.user,
        'password' => uri.password,
        'host'     => uri.host,
        'port'     => uri.port,
        'database' => uri.path.sub(%r{\A/}, '')
      }
    end
  end # of class methods
end
