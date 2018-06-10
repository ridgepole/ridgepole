require 'erb'
require 'yaml'

class Ridgepole::Config
  class << self
    def load(config, env = 'development')
      if config =~ /\Aenv:(.+)\z/
        config = ENV.fetch($1)
      end

      if File.exist?(config)
        parsed_config = parse_config_file(config)
      elsif (expanded = File.expand_path(config)) && File.exist?(expanded)
        parsed_config = parse_config_file(expanded)
      else
        parsed_config = YAML.safe_load(ERB.new(config).result, [], [], true)
      end

      unless parsed_config.kind_of?(Hash)
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
