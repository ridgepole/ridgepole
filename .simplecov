# frozen_string_literal: true

SimpleCov.configure do
  # exclude directories and files
  add_filter '/spec/'

  if ENV['CI']
    require 'simplecov-cobertura'
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end
