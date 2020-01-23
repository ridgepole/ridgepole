# frozen_string_literal: true

require 'erb'
require 'yaml'

module Ridgepole
  class Config
    class << self
      def load(config, env = 'development', spec_name = '')
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

        parsed_config = parsed_config.fetch(env.to_s) if parsed_config.key?(env.to_s)

        if parsed_config.key?(spec_name.to_s)
          parsed_config.fetch(spec_name.to_s)
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

        %w[scheme user host path].each do |key|
          value = uri.send(key)

          if value.nil? || value.empty?
            key = 'database' if key == 'path'
            raise "Invalid config: '#{key}' is empty: #{config.inspect}"
          end
        end

        query_hash =
          if uri.query
            uri.query.split('&').map { |pair| pair.split('=') }.to_h
          else
            {}
          end

        adapter = uri.scheme
        adapter = 'postgresql' if adapter == 'postgres'

        query_hash.merge(
          'adapter' => adapter,
          'username' => CGI.unescape(uri.user),
          'password' => uri.password ? CGI.unescape(uri.password) : nil,
          'host' => uri.host,
          'port' => uri.port,
          'database' => CGI.unescape(uri.path.sub(%r{\A/}, ''))
        )
      end
    end
  end
end
