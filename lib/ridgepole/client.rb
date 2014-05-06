class Ridgepole::Client
  def initialize(conn_spec, options = {})
    @options = options
    ActiveRecord::Base.establish_connection(conn_spec)

    @dumper = Ridgepole::Dumper.new(@options)
    @parser = Ridgepole::DSLParser.new(@options)
    @diff = Ridgepole::Diff.new(@options)
  end

  def dump
    @dumper.dump
  end

  def diff(dsl)
    expected_definition = @parser.parse(dsl)
    current_definition = @parser.parse(@dumper.dump)
    @diff.diff(current_definition, expected_definition)
  end
end
