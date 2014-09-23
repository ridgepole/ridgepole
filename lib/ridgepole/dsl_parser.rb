class Ridgepole::DSLParser
  class Context
    def self.include_module(mod)
      unless self.included_modules.include?(mod)
        include mod
      end
    end

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
        options = {:null => false}.merge(args.extract_options!)
        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
      end

      def references(*args)
        options = args.extract_options!
        polymorphic = options.delete(:polymorphic)
        args.each do |col|
          column("#{col}_id", :integer, options)
          column("#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) unless polymorphic.nil?
        end
      end
      alias :belongs_to :references
    end

    attr_reader :__definition
    attr_reader :__execute

    def initialize(opts = {})
      @__working_dir = File.expand_path(opts[:path] ? File.dirname(opts[:path]) : Dir.pwd)
      @__definition = {}
      @__execute = []
    end

    def self.eval(dsl, opts = {})
      ctx = self.new(opts)

      if opts[:path]
        ctx.instance_eval(dsl, opts[:path])
      else
        ctx.instance_eval(dsl)
      end

      [ctx.__definition, ctx.__execute]
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

    def execute(sql, name = nil, &cond)
      @__execute << {
        :sql => sql,
        :condition => cond,
      }
    end
  end

  def initialize(options = {})
    @options = options
  end

  def parse(dsl, opts = {})
    definition, execute = Context.eval(dsl, opts)
    check_orphan_index(definition)

    if @options[:enable_foreigner]
      Ridgepole::ForeignKey.check_orphan_foreign_key(definition)
    end

    [definition, execute]
  end

  private

  def check_orphan_index(definition)
    definition.each do |table_name, attrs|
      if attrs[:indices] and not attrs[:definition]
        raise "Table `#{table_name}` to create the index is not defined: #{attrs[:indices].keys.join(',')}"
      end
    end
  end
end
