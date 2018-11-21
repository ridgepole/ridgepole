module Ridgepole
  class DSLParser
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
          type: type,
          options: options,
        }
      end

      DEFAULT_PRIMARY_KEY_TYPE = Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('5.1') ? :bigint : :integer

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

        # https://github.com/rails/rails/blob/v5.1.1/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L184
        :virtual,

        # https://github.com/rails/rails/blob/v5.0.4/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L53
        :json
      ].uniq

      TYPES.each do |column_type|
        define_method column_type do |*args|
          options = args.extract_options!
          column_names = args
          column_names.each { |name| column(name, column_type, options) }
        end
      end

      ALIAS_TYPES = {
        # https://github.com/rails/rails/blob/v5.0.0.rc1/activerecord/lib/active_record/connection_adapters/mysql/schema_definitions.rb
        tinyblob: [:blob, { limit: 255 }],
        mediumblob: [:binary, { limit: 16_777_215 }],
        longblob: [:binary, { limit: 4_294_967_295 }],
        tinytext: [:text, { limit: 255 }],
        mediumtext: [:text, { limit: 16_777_215 }],
        longtext: [:text, { limit: 4_294_967_295 }],
        unsigned_integer: [:integer, { unsigned: true }],
        unsigned_bigint: [:bigint, { unsigned: true }],
        unsigned_float: [:float, { limit: 24, unsigned: true }],
        unsigned_decimal: [:decimal, { precision: 10, unsigned: true }],
      }.freeze

      # XXX:
      def blob(*args)
        options = args.extract_options!
        options = { limit: 65_535 }.merge(options)
        column_names = args

        column_names.each do |name|
          column_type = (0..0xff).cover?(options[:limit]) ? :blob : :binary
          column(name, column_type, options)
        end
      end

      ALIAS_TYPES.each do |alias_type, (column_type, default_options)|
        define_method alias_type do |*args|
          options = args.extract_options!
          options = default_options.merge(options)
          column_names = args
          column_names.each { |name| column(name, column_type, options) }
        end
      end

      def index(name, options = {})
        @base.add_index(@table_name, name, options)
      end

      def timestamps(*args)
        options = { null: false }.merge(args.extract_options!)
        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
      end

      def references(*args)
        options = args.extract_options!
        polymorphic = options.delete(:polymorphic)
        polymorphic_options = polymorphic.is_a?(Hash) ? polymorphic : {}
        # https://github.com/rails/rails/blob/5-2-1/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L167
        polymorphic_options.merge!(options.slice(:null, :first, :after))
        index_options = options.key?(:index) ? options.delete(:index) : true
        type = options.delete(:type) || DEFAULT_PRIMARY_KEY_TYPE

        args.each do |col|
          column("#{col}_id", type, options)
          column("#{col}_type", :string, polymorphic_options) if polymorphic
          if index_options
            columns = polymorphic ? ["#{col}_type", "#{col}_id"] : ["#{col}_id"]
            index(columns, index_options.is_a?(Hash) ? index_options : {})
          end
        end
      end
      alias belongs_to references
    end
  end
end
