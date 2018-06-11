class Ridgepole::DSLParser
  class Context
    attr_reader :__definition
    attr_reader :__execute

    def initialize(opts = {})
      @__working_dir = File.expand_path(opts[:path] ? File.dirname(opts[:path]) : Dir.pwd)
      @__definition = {}
      @__execute = []
    end

    def self.eval(dsl, opts = {})
      ctx = new(opts)

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

      if options[:primary_key] && options[:primary_key].is_a?(Symbol)
        options[:primary_key] = options[:primary_key].to_s
      end
      if options[:id] && TableDefinition::ALIAS_TYPES.key?(options[:id])
        type, type_default_opts = TableDefinition::ALIAS_TYPES[options[:id]]
        options[:id] = type
        options = type_default_opts.merge(options)
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
        column_name = [column_name].flatten.map(&:to_s)
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
      end

      if options[:length]
        options[:length] = options[:length].compact.symbolize_keys
      end

      @__definition[table_name][:indices][idx] = {
        column_name: column_name,
        options: options
      }
    end

    def add_foreign_key(from_table, to_table, options = {})
      from_table = from_table.to_s
      to_table = to_table.to_s
      options[:name] = options[:name].to_s if options[:name]
      @__definition[from_table] ||= {}
      @__definition[from_table][:foreign_keys] ||= {}
      idx = options[:name] || [from_table, to_table]

      if @__definition[from_table][:foreign_keys][idx]
        raise "Foreign Key `#{from_table}(#{idx})` already defined"
      end

      @__definition[from_table][:foreign_keys][idx] = {
        to_table: to_table,
        options: options
      }
    end

    def require(file)
      schemafile = file =~ %r{\A/} ? file : File.join(@__working_dir, file)

      if File.exist?(schemafile)
        instance_eval(File.read(schemafile), schemafile)
      elsif File.exist?(schemafile + '.rb')
        instance_eval(File.read(schemafile + '.rb'), schemafile + '.rb')
      else
        Kernel.require(file)
      end
    end

    def execute(sql, _name = nil, &cond)
      @__execute << {
        sql: sql,
        condition: cond
      }
    end
  end
end
