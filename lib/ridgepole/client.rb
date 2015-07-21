class Ridgepole::Client
  def initialize(conn_spec, options = {})
    @options = options

    ActiveRecord::Base.establish_connection(conn_spec)

    # XXX: If the required processing in class method?
    if not @options.has_key?(:index_removed_drop_column) and Ridgepole::DefaultsLimit.adapter == :postgresql
      @options[:index_removed_drop_column] = true
    end

    Ridgepole::ExecuteExpander.expand_execute(ActiveRecord::Base.connection)
    @dumper = Ridgepole::Dumper.new(@options)
    @parser = Ridgepole::DSLParser.new(@options)
    @diff = Ridgepole::Diff.new(@options)

    if @options[:enable_migration_comments]
      require 'migration_comments'
    end

    if @options[:enable_mysql_awesome]
      if @options[:enable_migration_comments]
        require 'ridgepole/ext/migration_comments'
      end

      require 'activerecord/mysql/awesome/base'
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
    expected_definition, expected_execute = @parser.parse(dsl, opts)
    logger.verbose_info('# Load tables')
    current_definition, current_execute = @parser.parse(@dumper.dump)
    logger.verbose_info('# Compare definitions')
    @diff.diff(current_definition, expected_definition, :execute => expected_execute)
  end

  class << self
    def diff(dsl_or_config1, dsl_or_config2, options = {})
      logger = Ridgepole::Logger.instance

      logger.verbose_info('# Parse DSL1')
      definition1, execute1 = load_definition(dsl_or_config1, options)
      logger.verbose_info('# Parse DSL2')
      definition2, execute2 = load_definition(dsl_or_config2, options)

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
      parse_opts = {}

      case dsl_or_config
      when Hash
        dsl_or_config = dump(dsl_or_config, options)
      when File
        file = dsl_or_config
        parse_opts[:path] = file.path
        dsl_or_config = file.read
        file.close
      end

      parser = Ridgepole::DSLParser.new(options)
      parser.parse(dsl_or_config, parse_opts)
    end
  end # of class methods
end
