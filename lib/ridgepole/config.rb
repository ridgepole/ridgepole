# -*- coding: utf-8 -*-
require 'erb'
require 'yaml'

module Ridgepole::Config
  def self.load(config, env='development')
    config = if File.exist?(config)
               yaml = ERB.new(File.read(config)).result
               YAML.load(yaml)
             else
               YAML.load(ERB.new(config).result)
             end
    if config.has_key? env.to_s
      config.fetch(env.to_s)
    else
      config
    end
  end
end
