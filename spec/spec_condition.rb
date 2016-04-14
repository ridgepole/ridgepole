module SpecCondition
  class << self
    def postgresql?
      ENV['POSTGRESQL'] == '1'
    end

    def mysql_awesome_enabled?
      ENV['ENABLE_MYSQL_AWESOME'] == '1'
    end

    def activerecord_5?
      ENV['BUNDLE_GEMFILE'] =~ /activerecord_5/
    end

    def debug?
      ENV['DEBUG'] == '1'
    end
  end

  def condition(*conds)
    conds.all? {|c| SpecCondition.send("#{c}?") }
  end
end
include SpecCondition
