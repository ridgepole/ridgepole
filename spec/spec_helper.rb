require 'ridgepole'

def restore_database
  sql_file = File.expand_path('../ridgepole_test.sql', __FILE__)
  system("mysql -uroot < #{sql_file}")
end

RSpec.configure do |config|
  config.before(:each) do
    restore_database
  end
end
