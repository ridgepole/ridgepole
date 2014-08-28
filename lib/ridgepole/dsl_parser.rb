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

    def initialize(opts = {})
      @__working_dir = File.expand_path(opts[:path] ? File.dirname(opts[:path]) : Dir.pwd)
      @__definition = {}
    end

    def self.eval(dsl, opts = {})
      ctx = self.new(opts)

      if opts[:path]
        ctx.instance_eval(dsl, opts[:path])
      else
        ctx.instance_eval(dsl)
      end

      ctx.__definition
    end

    def create_table(table_name, options = {})
      table_definition = TableDefinition.new
      yield(table_definition)
      @__definition[table_name] ||= {}

      if @__definition[table_name][:definition]
        raise "Table `#{table_name}` already defined"
      end

      @__definition[table_name][:definition] = table_definition.__definition
      options.delete(:force)
      @__definition[table_name][:options] = options
    end

    def add_index(table_name, column_name, options = {})
      column_name = [column_name].flatten
      @__definition[table_name] ||= {}
      @__definition[table_name][:indices] ||= {}
      idx = options[:name] || column_name

      if @__definition[table_name][:indices][idx]
        raise "Index `#{table_name}(#{idx})` already defined"
      end

      @__definition[table_name][:indices][idx] = {
        :column_name => column_name,
        :options => options,
      }
    end

    def require(file)
      schemafile = File.join(@__working_dir, file)

      if File.exist?(schemafile)
        instance_eval(File.read(schemafile), schemafile)
      elsif File.exist?(schemafile + '.rb')
        instance_eval(File.read(schemafile + '.rb'), schemafile + '.rb')
      else
        Kernel.require(file)
      end
    end
  end

  def initialize(options = {})
    @options = options
  end

  def parse(dsl, opts = {})
    parsed = Context.eval(dsl, opts)
    check_orphan_index(parsed)
    parsed
  end

  private

  def check_orphan_index(parsed)
    parsed.each do |table_name, attrs|
      if attrs.length == 1 and attrs[:indices]
        raise "Table `#{table_name}` to create the index is not defined: #{attrs[:indices].keys.join(',')}"
      end
    end
  end
end
