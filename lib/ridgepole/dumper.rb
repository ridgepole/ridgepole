class Ridgepole::Dumper
  def initialize(config = {})
    @config = config
  end

  def dump
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)

    stream.string.lines.select {|line|
      line !~ /\A#/ &&
      line !~ /\AActiveRecord::Schema\.define/ &&
      line !~ /\Aend/
    }.join.undent.strip
  end
end
