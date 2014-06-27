class Ridgepole::Client
  def initialize(conn_spec, options = {})
    @options = options
    ActiveRecord::Base.establish_connection(conn_spec)

    @dumper = Ridgepole::Dumper.new(@options)
    @parser = Ridgepole::DSLParser.new(@options)
    @diff = Ridgepole::Diff.new(@options)

    unless @options[:disable_mysql_unsigned]
      require 'activerecord-mysql-unsigned'
    end
  end

  def dump(&block)
    logger = Ridgepole::Logger.instance
    logger.verbose_info('# Load tables')
    @dumper.dump(&block)
  end

  def diff(dsl, opts = {})
    logger = Ridgepole::Logger.instance

    logger.verbose_info('# Parse DSL')
    expected_definition = @parser.parse(dsl, opts)
    logger.verbose_info('# Load tables')
    current_definition = @parser.parse(@dumper.dump)
    logger.verbose_info('# Compare definitions')
    @diff.diff(current_definition, expected_definition)
  end
end
