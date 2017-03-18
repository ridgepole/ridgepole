class Ridgepole::Dumper
  def initialize(options = {})
    @options = options
  end

  def dump
    stream = StringIO.new
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
        if ignore_tables.any? {|i| i =~ tbl } and not (target_tables and target_tables.include?(tbl))
          ActiveRecord::SchemaDumper.ignore_tables << tbl
        end
      end
    end

    ActiveRecord::SchemaDumper.dump(conn, stream)

    if target_tables or ignore_tables
      ActiveRecord::SchemaDumper.ignore_tables.clear
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
    not @options[:tables] or @options[:tables].include?(table_name)
  end
end
