require 'active_record'

module SpecCondition
  class << self
    def postgresql?
      ENV['POSTGRESQL'] == '1'
    end

    def mysql_awesome_enabled?
      ENV['ENABLE_MYSQL_AWESOME'] == '1'
    end

    def activerecord_4?
      ActiveRecord::VERSION::MAJOR >= 4 and ActiveRecord::VERSION::MAJOR < 5
    end

    def activerecord_5?
      ActiveRecord::VERSION::MAJOR >= 5 and ActiveRecord::VERSION::MAJOR < 6
    end

    def debug?
      ENV['DEBUG'] == '1'
    end
  end

  def condition(*conds)
    conds.any? do |c|
      if c.is_a? Array
        c.all? {|i| SpecCondition.send("#{i}?") }
      else
        SpecCondition.send("#{c}?")
      end
    end
  end
end
include SpecCondition
