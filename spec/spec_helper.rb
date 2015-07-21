$: << File.expand_path('..', __FILE__)

def travis?
  !!ENV['TRAVIS']
end

if travis?
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

if ENV['DEBUG']
  ActiveRecord::Migration.verbose = true
  logger = Ridgepole::Logger.instance
  logger.level = ::Logger::DEBUG
  ActiveRecord::Base.logger = logger
else
  ActiveRecord::Migration.verbose = false
  Ridgepole::Logger.instance.level = ::Logger::ERROR
end

RSpec.configure do |config|
  config.before(:each) do
    restore_database
  end
end

def restore_database
  if postgresql?
    restore_database_postgresql
  else
    restore_database_mysql
  end
end

def system_raise_on_fail(*args)
  unless system(*args)
    raise RuntimeError.new("Failed to run: #{args}")
  end
end

def restore_database_mysql
  sql_file = File.expand_path('../mysql/ridgepole_test_database.sql', __FILE__)
  system_raise_on_fail("mysql -uroot < #{sql_file}")
end

def restore_database_postgresql
  sql_file = File.expand_path('../postgresql/ridgepole_test_database.sql', __FILE__)
  system("createdb ridgepole_test #{travis? ? '-U postgres' : ''} 2>/dev/null")
  system_raise_on_fail("psql ridgepole_test #{travis? ? '-U postgres' : ''} --set ON_ERROR_STOP=off -q -f #{sql_file} 2>/dev/null")
end

def restore_tables
  if postgresql?
    restore_tables_postgresql
  else
    restore_tables_mysql
  end
end

def restore_tables_mysql
  sql_file = File.expand_path('../mysql/ridgepole_test_tables.sql', __FILE__)
  system_raise_on_fail("mysql -uroot < #{sql_file}")
end

def restore_tables_postgresql
  sql_file = File.expand_path('../postgresql/ridgepole_test_tables.sql', __FILE__)
  system_raise_on_fail("psql ridgepole_test #{travis? ? '-U postgres' : ''} -q -f #{sql_file} 2>/dev/null")
end

def client(options = {}, config = {})
  config = conn_spec(config)

  default_options = {
    :debug => !!ENV['DEBUG'],
  }

  if mysql_awesome_enabled?
    default_options[:enable_mysql_awesome] = true
    default_options[:dump_without_table_options] = true
  end

  options = default_options.merge(options)

  Ridgepole::Client.new(config, options)
end

def conn_spec(config = {})
  if postgresql?
    spec = {
      adapter: 'postgresql',
      database: TEST_SCHEMA,
    }

    spec[:username] = 'postgres' if travis?
    spec.merge(config)
  else
    {
      adapter: 'mysql2',
      database: TEST_SCHEMA,
    }.merge(config)
  end
end

def show_create_table(table_name)
  if postgresql?
    show_create_table_postgresql(table_name)
  else
    show_create_table_mysql(table_name)
  end
end

def show_create_table_mysql(table_name)
  raw_conn = ActiveRecord::Base.connection.raw_connection
  raw_conn.query("SHOW CREATE TABLE `#{table_name}`").first[1]
end

def show_create_table_postgresql(table_name)
  `pg_dump #{travis? ? '-U postgres' : ''} --schema-only #{TEST_SCHEMA} --table=#{table_name} | awk '/^CREATE TABLE/,/);/{print} /^CREATE INDEX/{print}'`.strip
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
        puts "Ridgepole::Client#initialize([\#{args.map {|i| i.kind_of?(File) ? i.path : i.inspect}.join(', ')}])"
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
          puts "Ridgepole::Client.diff([\#{args.map {|i| i.kind_of?(File) ? i.path : i.inspect}.join(', ')}])"
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

def mysql_awesome_enabled?
  ENV['ENABLE_MYSQL_AWESOME'] == '1'
end

def migration_comments_enabled?
  ENV['ENABLE_MIGRATION_COMMENTS'] == '1'
end

def postgresql?
  ENV['POSTGRESQL'] == '1'
end

def if_mysql_awesome_enabled(then_str, else_str = '')
  if mysql_awesome_enabled?
    then_str
  else
    else_str
  end
end

def unsigned_if_enabled(prefix = ', ', suffix = '')
  if_mysql_awesome_enabled("#{prefix}unsigned: true#{suffix}")
end

def unsigned_false_if_enabled(prefix = ', ', suffix = '')
  if_mysql_awesome_enabled("#{prefix}unsigned: false#{suffix}")
end

def unsigned_if_enabled2(prefix = ', ', suffix = '')
  if_mysql_awesome_enabled("#{prefix}:unsigned=>true#{suffix}")
end

def unsigned_false_if_enabled2(prefix = ', ', suffix = '')
  if_mysql_awesome_enabled("#{prefix}:unsigned=>false#{suffix}")
end

def run_ridgepole(*args)
  Dir.chdir(File.expand_path('../..', __FILE__)) do
    cmd = [:bundle, :exec, './bin/ridgepole'] + args
    Open3.capture2e(cmd.join(' '))
  end
end
