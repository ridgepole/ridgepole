require 'erb'
require 'yaml'

module Ridgepole
  class Config
    class << self
      def load(config, env = 'development')
        config = ENV.fetch(Regexp.last_match(1)) if config =~ /\Aenv:(.+)\z/

        parsed_config = if File.exist?(config)
                          parse_config_file(config)
                        elsif (expanded = File.expand_path(config)) && File.exist?(expanded)
                          parse_config_file(expanded)
                        elsif Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0.pre1') # Ruby 2.6
                          YAML.safe_load(
                            ERB.new(config).result,
                            permitted_classes: [],
                            permitted_symbols: [],
                            aliases: true
                          )
                        else
                          YAML.safe_load(ERB.new(config).result, [], [], true)
                        end

        parsed_config = parse_database_url(config) unless parsed_config.is_a?(Hash)

        if parsed_config.key?(env.to_s)
          parsed_config.fetch(env.to_s)
        else
          parsed_config
        end
      end

      private

      def parse_config_file(path)
        yaml = ERB.new(File.read(path)).result

        if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0.pre1') # Ruby 2.6
          YAML.safe_load(
            yaml,
            permitted_classes: [],
            permitted_symbols: [],
            aliases: true
          )
        else
          YAML.safe_load(yaml, [], [], true)
        end
      end

      def parse_database_url(config)
        uri = URI.parse(config)

        raise "Invalid config: #{config.inspect}" if [uri.scheme, uri.user, uri.host, uri.path].any? { |i| i.nil? || i.empty? }

        {
          'adapter' => uri.scheme,
          'username' => CGI.unescape(uri.user),
          'password' => CGI.unescape(uri.password),
          'host' => uri.host,
          'port' => uri.port,
          'database' => CGI.unescape(uri.path.sub(%r{\A/}, '')),
        }
      end
    end
  end
end
