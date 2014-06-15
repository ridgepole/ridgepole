class Ridgepole::Dumper
  def initialize(options = {})
    @options = options
  end

  def dump
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)

    dsl = stream.string.lines.select {|line|
      line !~ /\A#/ &&
      line !~ /\AActiveRecord::Schema\.define/ &&
      line !~ /\Aend/
    }.join.undent.strip

    definitions = []

    each_table(dsl) do |name, definition|
      if not @options[:tables] or @options[:tables].include?(name)
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
end
