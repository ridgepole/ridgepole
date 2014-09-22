class Ridgepole::DSLParser::Context
  module ForeignKey
    class << self
      def init
        require 'foreigner'

        ActiveSupport.on_load :active_record do
          Foreigner.load
        end

        Ridgepole::DSLParser::Context.include_module(
          Ridgepole::DSLParser::Context::ForeignKey)
      end
    end # of class methods

    def add_foreign_key(from_table, to_table, options = {})
    end
  end
end
