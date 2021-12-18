# frozen_string_literal: true

module Ridgepole
  class ExecuteExpander
    class Stub
      def method_missing(_method_name, *_args, &_block)
        # Nothing to do
      end

      def respond_to_missing?(_symbol, _include_private)
        true
      end
    end

    module ConnectionAdapterExt
      def execute(*args)
        sql = args.fetch(0)
        name = args[1]

        if Ridgepole::ExecuteExpander.noop
          if (callback = Ridgepole::ExecuteExpander.callback)
            sql = append_alter_extra(sql)
            callback.call(sql, name)
          end

          if /\A(SELECT|SHOW)\b/i.match?(sql)
            begin
              super(sql, name)
            rescue StandardError
              Stub.new
            end
          else
            Stub.new
          end
        elsif Ridgepole::ExecuteExpander.use_script
          if /\A(SELECT|SHOW)\b/i.match?(sql)
            super(sql, name)
          else
            sql = append_alter_extra(sql)
            Ridgepole::ExecuteExpander.sql_executer.execute(sql)
            nil
          end
        else
          sql = append_alter_extra(sql)
          super(sql, name)
        end
      end

      private

      def append_alter_extra(sql)
        if Ridgepole::ExecuteExpander.alter_extra
          case sql
          when /\AALTER\b/i
            sql += ',' + Ridgepole::ExecuteExpander.alter_extra
          when /\A(CREATE|DROP)\s+((ONLINE|OFFLINE)\s+)?((UNIQUE|FULLTEXT|SPATIAL)\s+)?INDEX\b/i
            # https://dev.mysql.com/doc/refman/5.6/en/create-index.html
            # https://dev.mysql.com/doc/refman/5.6/en/drop-index.html
            sql += ' ' + Ridgepole::ExecuteExpander.alter_extra.tr(',', ' ')
          end
        end

        sql
      end
    end

    cattr_accessor :noop,         instance_writer: false, instance_reader: false
    cattr_accessor :callback,     instance_writer: false, instance_reader: false
    cattr_accessor :use_script,   instance_writer: false, instance_reader: false
    cattr_accessor :sql_executer, instance_writer: false, instance_reader: false
    cattr_accessor :alter_extra,  instance_writer: false, instance_reader: false

    class << self
      def without_operation(callback = nil)
        self.noop = true
        self.callback = callback
        yield
      ensure
        self.noop = false
        self.callback = nil
      end

      def with_script(script, logger)
        self.use_script = true
        self.sql_executer = Ridgepole::ExternalSqlExecuter.new(script, logger)
        yield
      ensure
        self.use_script = false
        self.sql_executer = nil
      end

      def with_alter_extra(extra)
        self.alter_extra = extra
        yield
      ensure
        self.alter_extra = nil
      end

      def expand_execute(connection)
        return if connection.is_a?(ConnectionAdapterExt)

        connection.class_eval do
          prepend ConnectionAdapterExt
        end
      end
    end
  end
end
