class Ridgepole::Client
  def initialize(conn_spec, options = {})
    @options = options
    ActiveRecord::Base.establish_connection(conn_spec)
    Ridgepole::ExecuteExpander.expand_execute(ActiveRecord::Base.connection)
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

  class << self
    def diff(dsl_or_config1, dsl_or_config2, options = {})
      logger = Ridgepole::Logger.instance

      logger.verbose_info('# Parse DSL1')
      definition1 = load_definition(dsl_or_config1)
      logger.verbose_info('# Parse DSL2')
      definition2 = load_definition(dsl_or_config2)

      logger.verbose_info('# Compare definitions')
      diff = Ridgepole::Diff.new(options)
      diff.diff(definition1, definition2)
    end

    def dump(conn_spec, options = {}, &block)
      client = self.new(conn_spec, options)
      client.dump(&block)
    end

    private

    def load_definition(dsl_or_config, options = {})
      dsl_or_config = dump(dsl_or_config, options) if dsl_or_config.kind_of?(Hash)
      parser = Ridgepole::DSLParser.new(options)
      parser.parse(dsl_or_config)
    end
  end # of class methods
end
