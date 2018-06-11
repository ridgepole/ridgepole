class Ridgepole::Dumper
  def initialize(options = {})
    @options = options
    @logger = Ridgepole::Logger.instance
  end

  def dump
    conn = ActiveRecord::Base.connection
    target_tables = @options[:tables]
    ignore_tables = @options[:ignore_tables]

    if target_tables
      conn.data_sources.each do |tbl|
        next if target_tables.include?(tbl)
        ActiveRecord::SchemaDumper.ignore_tables << tbl
      end
    end

    if ignore_tables
      conn.data_sources.each do |tbl|
        if ignore_tables.any? { |i| i =~ tbl } && !(target_tables && target_tables.include?(tbl))
          ActiveRecord::SchemaDumper.ignore_tables << tbl
        end
      end
    end

    stream = dump_from(conn)

    if target_tables || ignore_tables
      ActiveRecord::SchemaDumper.ignore_tables.clear
    end

    stream.string.lines.each_cons(2) do |first_line, second_line|
      if first_line =~ /\A# Could not dump/
        @logger.warn("[WARNING] #{first_line.sub(/\A# /, '').chomp}")
        @logger.warn(second_line.sub(/\A#/, '').chomp)
      end
    end

    dsl = stream.string.lines.select do |line|
      line !~ /\A#/ &&
        line !~ /\AActiveRecord::Schema\.define/ &&
        line !~ /\Aend/
    end

    dsl = dsl.join.strip_heredoc

    definitions = []

    each_table(dsl) do |name, definition|
      if target?(name)
        definitions << definition
        yield(name, definition) if block_given?
      end
    end

    definitions.join("\n\n")
  end

  private

  def each_table(dsl)
    name = nil
    definition = []

    pass = proc do
      if name
        yield(name, definition.join.strip)
        name = nil
        definition = []
      end
    end

    dsl.lines.each do |line|
      if line =~ /\Acreate_table/
        pass.call
        name = line.split(/[\s,'"]+/)[1]
        definition << line
      elsif name
        definition << line
      end
    end

    pass.call
  end

  def target?(table_name)
    !(@options[:tables]) || @options[:tables].include?(table_name)
  end

  def dump_from(conn)
    stream = StringIO.new
    conn.without_table_options(@options[:dump_without_table_options]) do
      ActiveRecord::SchemaDumper.with_default_fk_name(@options[:dump_with_default_fk_name]) do
        ActiveRecord::SchemaDumper.dump(conn, stream)
      end
    end
    stream
  end
end
