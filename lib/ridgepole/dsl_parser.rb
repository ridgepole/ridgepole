class Ridgepole::DSLParser
  class Context
    class TableDefinition
      attr_reader :__definition

      def initialize
        @__definition = {}
      end

      def column(name, type, options = {})
        @__definition[name] = {
          :type => type,
          :options => options,
        }
      end

      TYPES = [
        :string,
        :text,
        :integer,
        :float,
        :decimal,
        :datetime,
        :timestamp,
        :time,
        :date,
        :binary,
        :boolean
      ]

      TYPES.each do |column_type|
        define_method column_type do |*args|
          options = args.extract_options!
          column_names = args
          column_names.each {|name| column(name, column_type, options) }
        end
      end
    end

    attr_reader :__definition

    def initialize
      @__definition = {}
    end

    def self.eval(dsl)
      ctx = self.new
      ctx.instance_eval(dsl)
      ctx.__definition
    end

    def create_table(table_name, options = {})
      # XXX: Add exist check
      table_definition = TableDefinition.new
      yield(table_definition)
      @__definition[table_name] ||= {}
      @__definition[table_name][:definition] = table_definition.__definition
      options.delete(:force)
      @__definition[table_name][:options] = options
    end

    def add_index(table_name, column_name, options = {})
      # XXX: Add exist check
      @__definition[table_name] ||= {}
      @__definition[table_name][:indices] ||= {}
      idx = options[:name] || column_name
      @__definition[table_name][:indices][idx] = {
        :column_name => column_name,
        :options => options,
      }
    end
  end

  def initialize(config = {})
    @config = config
  end

  def parse(dsl)
    Context.eval(dsl)
  end
end
