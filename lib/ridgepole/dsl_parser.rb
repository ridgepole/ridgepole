class Ridgepole::DSLParser
  class Context
    class TableDefinition
      attr_reader :__definition

      def initialize
        @__definition = {}
      end

      def column(name, type, options = {})
        name = name.to_s

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

      def timestamps(*args)
        options = { :null => false }.merge(args.extract_options!)
        column(:created_at, :datetime, options.dup)
        column(:updated_at, :datetime, options.dup)
      end

      def references(*args)
        options = args.extract_options!
        polymorphic = options.delete(:polymorphic)
        args.each do |col|
          column("#{col}_id", :integer, options.dup)
          column("#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options.dup) unless polymorphic.nil?
        end
      end
      alias :belongs_to :references
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
      table_name = table_name.to_s
      table_definition = TableDefinition.new

      [:primary_key].each do |key|
        options[key] = options[key].to_s if options[key]
      end

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
      table_name = table_name.to_s
      column_name = [column_name].flatten.map {|i| i.to_s }
      options[:name] = options[:name].to_s if options[:name]
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
