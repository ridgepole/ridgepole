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

            Stub.new
          else
            execute_without_noop(sql, name)
          end
        end
        alias_method_chain :execute, :noop
      end
    end
  end # of class methods
end
