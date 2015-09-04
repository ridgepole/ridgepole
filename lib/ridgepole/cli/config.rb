require 'erb'
require 'yaml'
require 'uri'

class Ridgepole::Config
  class << self
    def load(config, env = 'development')
      parsed_config = if File.exist?(config)
                        parse_config_file(config)
                      else
                        YAML.load(ERB.new(config).result)
                      end

      unless parsed_config.kind_of?(Hash)
        config = File.expand_path(config)
        parse_config = parse_config_file(config)
      end

      if parsed_config.has_key?(env.to_s)
        parsed_config.fetch(env.to_s)
      else
        parsed_config
      end
    end

    def load_env_param(database_url)
      parsed_uri = URI.parse(database_url)

      parsed_config = {}
      parsed_config[:adapter] = parsed_uri.scheme
      parsed_config[:adapter] = "postgresql" if parsed_config[:adapter] == "postgres"
      parsed_config[:database] = (parsed_uri.path || "").split("/")[1]
      parsed_config[:username] = parsed_uri.user
      parsed_config[:password] = parsed_uri.password
      parsed_config[:host] = parsed_uri.host
      parsed_config[:port] = parsed_uri.port
      parsed_config
    end

    private

    def parse_config_file(path)
      yaml = ERB.new(File.read(path)).result
      YAML.load(yaml)
    end
  end # of class methods
end
