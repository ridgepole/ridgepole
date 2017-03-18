$: << File.expand_path('..', __FILE__)

require 'spec_const'
require 'spec_condition'
require 'cli_helper'

require 'processing_for_travis'

require 'ridgepole'
require 'ridgepole/cli/config'
require 'active_support/core_ext'
require 'string_ext' # TODO: must be remove
require 'open3'
require 'tempfile'
require 'json'
require 'rspec/match_fuzzy'
require 'erbh'
require 'hash_modern_inspect'
require 'hash_order_helper'

require 'erb_helper'

RSpec.configure do |config|
  config.before(:all) do
    if condition(:debug)
      ActiveRecord::Migration.verbose = true
      logger = Ridgepole::Logger.instance
      logger.level = ::Logger::DEBUG
      ActiveRecord::Base.logger = logger
    else
      ActiveRecord::Migration.verbose = false
      Ridgepole::Logger.instance.level = ::Logger::ERROR
    end
  end

  config.before(:each) do |example|
    if conds = example.metadata[:condition]
      skip unless Array(conds).any? {|c| condition(*c) }
    end

    case example.metadata[:file_path]
    when /mysql/
      skip if condition(:postgresql)
    when /postgresql/
      skip unless condition(:postgresql)
    end

    restore_database
  end
end

module SpecHelper
  def restore_database
    if condition(:postgresql)
      restore_database_postgresql
    else
      restore_database_mysql
    end
  end

  def system_raise_on_fail(*args)
    unless system(*args)
      raise "Failed to run: #{args}"
    end
  end

  def restore_database_mysql
    sql_file = File.expand_path('../mysql/ridgepole_test_database.sql', __FILE__)
    system_raise_on_fail("#{MYSQL_CLI} < #{sql_file}")
  end

  def restore_database_postgresql
    sql_file = File.expand_path('../postgresql/ridgepole_test_database.sql', __FILE__)
    system("#{PG_CREATEDB} ridgepole_test 2>/dev/null")
    system_raise_on_fail("#{PG_PSQL} ridgepole_test --set ON_ERROR_STOP=off -q -f #{sql_file} 2>/dev/null")
  end

  def restore_tables
    if condition(:postgresql)
      restore_tables_postgresql
    else
      restore_tables_mysql
    end
  end

  def restore_tables_mysql
    sql_file = File.expand_path('../mysql/ridgepole_test_tables.sql', __FILE__)
    system_raise_on_fail("#{MYSQL_CLI} < #{sql_file}")
  end

  def restore_tables_postgresql
    sql_file = File.expand_path('../postgresql/ridgepole_test_tables.sql', __FILE__)
    system_raise_on_fail("#{PG_PSQL} ridgepole_test -q -f #{sql_file} 2>/dev/null")
  end

  def client(options = {}, config = {})
    config = conn_spec(config)
    default_options = {debug: condition(:debug)}
    default_options[:dump_without_table_options] = true

    options = default_options.merge(options)

    Ridgepole::Client.new(config, options)
  end

  def conn_spec(config = {})
    if condition(:postgresql)
      {
        adapter: 'postgresql',
        database: TEST_SCHEMA,
        host: TEST_PG_HOST,
        port: TEST_PG_PORT,
        username: TEST_PG_USER,
        password: TEST_PG_PASS,
      }.merge(config)
    else
      {
        adapter: 'mysql2',
        database: TEST_SCHEMA,
        host: TEST_MYSQL_HOST,
        port: TEST_MYSQL_PORT,
        username: TEST_MYSQL_USER,
        password: TEST_MYSQL_PASS,
      }.merge(config)
    end
  end

  def show_create_table(table_name)
    if condition(:postgresql)
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
    `#{PG_DUMP} --schema-only #{TEST_SCHEMA} --table=#{table_name} | awk '/^CREATE TABLE/,/);/{print} /^CREATE INDEX/{print}'`.strip
  end

  def tempfile(basename, content = '')
    begin
      path = `mktemp /tmp/#{basename}.XXXXXX`
      open(path, 'wb') {|f| f << content }
      FileUtils.chmod(0777, path)
      yield(path)
    ensure
      FileUtils.rm_f(path) if path
    end
  end

  def run_ridgepole(*args)
    Dir.chdir(File.expand_path('../..', __FILE__)) do
      cmd = [:bundle, :exec, './bin/ridgepole'] + args
      Open3.capture2e(cmd.join(' '))
    end
  end
end
include SpecHelper
