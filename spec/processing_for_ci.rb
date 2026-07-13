# frozen_string_literal: true

if ENV['CI']
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = 'coverage/lcov.info'
  end
  SimpleCov.formatters = [SimpleCov::Formatter::LcovFormatter]
  SimpleCov.start
end
