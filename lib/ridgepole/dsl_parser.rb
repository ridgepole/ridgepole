class Ridgepole::DSLParser
  class Context
    class TableDefinition
      attr_reader :__definition

      def initialize(table_name, base)
        @__definition = {}
        @table_name = table_name
        @base = base
      end

      def column(name, type, options = {})
        name = name.to_s

        @__definition[name] = {
          :type => type,
          :options => options,
        }
      end

      TYPES = [
        # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L274
        :string,
        :text,
        :integer,
        :bigint,
        :float,
        :decimal,
        :datetime,
        :timestamp,
        :time,
        :date,
        :binary,
        :boolean,

        # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L79
        :daterange,
        :numrange,
        :tsrange,
        :tstzrange,
        :int4range,
        :int8range,
        :binary,
        :boolean,
        :bigint,
        :xml,
        :tsvector,
        :hstore,
        :inet,
        :cidr,
        :macaddr,
        :uuid,
        :json,
        :jsonb,
        :ltree,
        :citext,
        :point,
        :bit,
        :bit_varying,
        :money,
      ].uniq

      TYPES.each do |column_type|
        define_method column_type do |*args|
          options = args.extract_options!
          column_names = args
          column_names.each {|name| column(name, column_type, options) }
        end
      end

      ALIAS_TYPES = {
        # https://github.com/rails/rails/blob/v5.0.0.rc1/activerecord/lib/active_record/connection_adapters/mysql/schema_definitions.rb
        tinyblob: [:blob, {limit: 255}],
        mediumblob: [:binary, {limit: 16777215}],
        longblob: [:binary, {limit: 4294967295}],
        tinytext: [:text, {limit: 255}],
        mediumtext: [:text, {limit: 16777215}],
        longtext: [:text, {limit: 4294967295}],
        unsigned_integer: [:integer, {unsigned: true}],
        unsigned_bigint: [:bigint, {unsigned: true}],
        unsigned_float: [:float, {limit: 24, unsigned: true}],
        unsigned_decimal: [:decimal, {precision: 10, unsigned: true}],
      }

      # XXX:
      def blob(*args)
        options = args.extract_options!
        options = {limit: 65535}.merge(options)
        column_names = args

        column_names.each do |name|
          column_type = (0..0xff).include?(options[:limit]) ? :blob : :binary
          column(name, column_type, options)
        end
      end

      ALIAS_TYPES.each do |alias_type, (column_type, default_options)|
        define_method alias_type do |*args|
          options = args.extract_options!
          options = default_options.merge(options)
          column_names = args
          column_names.each {|name| column(name, column_type, options) }
        end
      end

      def index(name, options = {})
        @base.add_index(@table_name, name, options)
      end

      def timestamps(*args)
        options = {:null => false}.merge(args.extract_options!)
        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
      end

      def references(*args)
        options = args.extract_options!
        polymorphic = options.delete(:polymorphic)
        index_options = options.delete(:index)
        type = options.delete(:type) || :integer

        args.each do |col|
          column("#{col}_id", type, options)
          column("#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) if polymorphic
          if index_options
            index("#{col}_id", index_options.is_a?(Hash) ? index_options : {})
            index("#{col}_type", index_options.is_a?(Hash) ? index_options : {}) if polymorphic
          end
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
      table_definition = TableDefinition.new(table_name, self)

      if options[:primary_key] and options[:primary_key].is_a?(Symbol)
        options[:primary_key] = options[:primary_key].to_s
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
      # Keep column_name for expression index support
      # https://github.com/rails/rails/pull/23393
      unless column_name.is_a?(String) && /\W/ === column_name
        column_name = [column_name].flatten.map {|i| i.to_s }
      end
      options[:name] = options[:name].to_s if options[:name]
      @__definition[table_name] ||= {}
      @__definition[table_name][:indices] ||= {}
      idx = options[:name] || column_name

      if @__definition[table_name][:indices][idx]
        raise "Index `#{table_name}(#{idx})` already defined"
      end

      if options[:length].is_a?(Numeric)
        index_length = options[:length]
        options[:length] = {}

        column_name.each do |col|
          options[:length][col] = index_length
        end

        # XXX: fix for https://github.com/rails/rails/commit/5025fd3a99c68f95bdd6fd43f382c62e9653236b
        if ActiveRecord::VERSION::MAJOR >= 6 or (ActiveRecord::VERSION::MAJOR == 5 and (ActiveRecord::VERSION::MINOR >= 1 or ActiveRecord::VERSION::TINY >= 1))
          options[:length] = options[:length].symbolize_keys
        end
      end

      @__definition[table_name][:indices][idx] = {
        :column_name => column_name,
        :options => options,
      }
    end

    def add_foreign_key(from_table, to_table, options = {})
      unless options[:name]
        raise "Foreign key name in `#{from_table}` is undefined"
      end

      from_table = from_table.to_s
      to_table = to_table.to_s
      options[:name] = options[:name].to_s
      @__definition[from_table] ||= {}
      @__definition[from_table][:foreign_keys] ||= {}
      idx = options[:name]

      if @__definition[from_table][:foreign_keys][idx]
        raise "Foreign Key `#{from_table}(#{idx})` already defined"
      end

      @__definition[from_table][:foreign_keys][idx] = {
        :to_table => to_table,
        :options => options,
      }
    end

    def require(file)
      schemafile = (file =~ %r|\A/|) ? file : File.join(@__working_dir, file)

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
    check_orphan_foreign_key(definition)
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

  def check_orphan_foreign_key(definition)
    definition.each do |table_name, attrs|
      if attrs[:foreign_keys] and not attrs[:definition]
        raise "Table `#{table_name}` to create the foreign key is not defined: #{attrs[:foreign_keys].keys.join(',')}"
      end
    end
  end
end
