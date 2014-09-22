$: << File.expand_path('..', __FILE__)

if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'ridgepole'
require 'ridgepole/cli/config'
require 'active_support/core_ext/string/strip'
require 'string_ext'
require 'open3'
require 'tempfile'
require 'json'

TEST_SCHEMA = 'ridgepole_test'

ActiveRecord::Migration.verbose = false
Ridgepole::Logger.instance.level = ::Logger::ERROR

RSpec.configure do |config|
  config.before(:each) do
    restore_database
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

def client(options = {}, config = {})
  config = conn_spec(config)

  options = {
    :enable_mysql_unsigned => true,
  }.merge(options)

  Ridgepole::Client.new(config, options)
end

def conn_spec(config = {})
  {
    adapter: 'mysql2',
    database: TEST_SCHEMA,
  }.merge(config)
end

def show_create_table(table_name)
  raw_conn = ActiveRecord::Base.connection.raw_connection
  raw_conn.query("SHOW CREATE TABLE `#{table_name}`").first[1]
end

def default_cli_hook
  <<-RUBY.strip_heredoc
    require 'ridgepole'

    class Ridgepole::Delta
      def initialize(*args);
      end
      def migrate(*args)
        puts "Ridgepole::Delta#migrate"
        [#{differ}, "create_table :table do\\nend"]
      end
      def script
        puts "Ridgepole::Delta#script"

        "create_table :table do\\nend"
      end
      def differ?
        puts "Ridgepole::Delta#differ?"
        #{differ}
      end
    end

    class Ridgepole::Client
      def initialize(*args)
        puts "Ridgepole::Client#initialize(\#{args.inspect})"
      end
      def dump
        puts "Ridgepole::Client#dump"
      end
      def diff(*args)
        puts "Ridgepole::Client#diff"
        Ridgepole::Delta.new
      end
      class << self
        def diff(*args)
          puts "Ridgepole::Client.diff(\#{args.inspect})"
          Ridgepole::Delta.new
        end
        def dump(args)
          puts "Ridgepole::Client.dump"
        end
      end
    end
  RUBY
end

def run_cli(options = {})
  args = options[:args] || []
  hook = options[:hook] || default_cli_hook
  path = File.expand_path('../../bin/ridgepole', __FILE__)

  Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.rb']) do |f|
    f.puts(hook)
    f.puts(File.read(path))
    f.flush

    cmd = ([:ruby, f.path] + args).join(' ')
    Open3.capture2e(cmd)
  end
end
