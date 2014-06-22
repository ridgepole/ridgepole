$: << File.expand_path('..', __FILE__)
require 'ridgepole'
require 'string_ext'

RSpec.configure do |config|
  config.before(:each) do
    restore_database
  end
end

RSpec::Matchers.define :be_same_str_as do |expected|
  match do |actual|
    normalize = proc do |str|
      str.undent.strip
    end

    normalize[actual] == normalize[expected]
  end
end

def restore_database
  sql_file = File.expand_path('../ridgepole_test_database.sql', __FILE__)
  system("mysql -uroot < #{sql_file}")
end

def restore_tables
  sql_file = File.expand_path('../ridgepole_test_tables.sql', __FILE__)
  system("mysql -uroot < #{sql_file}")
end

def client(config = {}, options = {})
  config = {
    adapter: 'mysql2',
    database: 'ridgepole_test',
  }.merge(config)

  options = {
  }.merge(options)

  Ridgepole::Client.new(config, options)
end