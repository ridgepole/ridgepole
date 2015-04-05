require 'erb'
require 'yaml'

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

    private

    def parse_config_file(path)
      yaml = ERB.new(File.read(path)).result
      YAML.load(yaml)
    end
  end # of class methods
end
