class Ridgepole::DSLParser
  def initialize(options = {})
    @options = options
  end

  def parse(dsl, opts = {})
    definition, execute = Context.eval(dsl, opts)
    check_orphan_index(definition)
    check_orphan_foreign_key(definition)
    [definition, execute]
  end

  private

  def check_orphan_index(definition)
    definition.each do |table_name, attrs|
      if attrs[:indices] && !(attrs[:definition])
        raise "Table `#{table_name}` to create the index is not defined: #{attrs[:indices].keys.join(',')}"
      end
    end
  end

  def check_orphan_foreign_key(definition)
    definition.each do |table_name, attrs|
      if attrs[:foreign_keys] && !(attrs[:definition])
        raise "Table `#{table_name}` to create the foreign key is not defined: #{attrs[:foreign_keys].keys.join(',')}"
      end
    end
  end
end
