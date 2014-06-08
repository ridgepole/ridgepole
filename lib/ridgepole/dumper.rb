class Ridgepole::Dumper
  def initialize(options = {})
    @options = options
  end

  def dump(&block)
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)

    dsl = stream.string.lines.select {|line|
      line !~ /\A#/ &&
      line !~ /\AActiveRecord::Schema\.define/ &&
      line !~ /\Aend/
    }.join.undent.strip

    each_table(dsl, &block) if block

    dsl
  end

  private

  def each_table(dsl, &block)
    name = nil
    definition = []

    pass = proc do
      if name
        block.call(name, definition.join.strip)
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
