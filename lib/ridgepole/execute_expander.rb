class Ridgepole::ExecuteExpander
  class Stub
    def method_missing(method_name, *args, &block)
      # Nothing to do
    end
  end

  cattr_accessor :noop,     :instance_writer => false, :instance_reader => false
  cattr_accessor :callback, :instance_writer => false, :instance_reader => false

  class << self
    def without_operation(callback = nil)
      begin
        self.noop = true
        self.callback = callback
        yield
      ensure
        self.noop = false
        self.callback = nil
      end
    end

    def expand_execute(connection)
      return if connection.respond_to?(:execute_with_noop)

      class << connection
        def execute_with_noop(sql, name = nil)
          if Ridgepole::ExecuteExpander.noop
            if (callback = Ridgepole::ExecuteExpander.callback)
              callback.call(sql, name)
            end

            if sql =~ /\A(SELECT|SHOW)\b/i
              begin
                execute_without_noop(sql, name)
              rescue => e
                Stub.new
              end
            else
              Stub.new
            end
          else
            execute_without_noop(sql, name)
          end
        end
        alias_method_chain :execute, :noop
      end
    end
  end # of class methods
end

require 'active_record/connection_adapters/abstract/schema_statements'

module ActiveRecord::ConnectionAdapters::SchemaStatements
  def index_name_exists_with_noop?(table_name, column_name, options = {})
    if Ridgepole::ExecuteExpander.noop
      caller_methods = caller.map {|i| i =~ /:\d+:in `(.+)'/ ? $1 : '' }

      if caller_methods.any? {|i| i =~ /\Aremove_index/ }
        true
      elsif caller_methods.any? {|i| i =~ /\Aadd_index/ }
        false
      else
        index_name_exists_without_noop?(table_name, column_name, options)
      end
    else
      index_name_exists_without_noop?(table_name, column_name, options)
    end
  end
  alias_method_chain :index_name_exists?, :noop
end
