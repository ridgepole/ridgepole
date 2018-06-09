require 'active_record'

module SpecCondition
  class << self
    def postgresql?
      ENV['POSTGRESQL'] == '1'
    end

    def mysql57?
      ENV['MYSQL57'] == '1'
    end

    def mysql_awesome_enabled?
      ENV['ENABLE_MYSQL_AWESOME'] == '1'
    end

    def activerecord_5?
      (ActiveRecord::VERSION::MAJOR >= 5) && (ActiveRecord::VERSION::MAJOR < 6)
    end

    def debug?
      ENV['DEBUG'] == '1'
    end
  end

  def check_version_or_cond(version_or_cond)
    case version_or_cond
    when Regexp
      ActiveRecord::VERSION::STRING =~ version_or_cond
    when Float
      ActiveRecord::VERSION::STRING.start_with?(version_or_cond.to_s)
    when /\s+/
      ar_version = Gem::Version.new(ActiveRecord::VERSION::STRING)

      version_or_cond.split(',').all? do |ope_version|
        ope, version = ope_version.strip.split(/\s+/, 2)
        ar_version.send(ope, Gem::Version.new(version))
      end
    when String
      ActiveRecord::VERSION::STRING.start_with?(version_or_cond)
    else
      SpecCondition.send("#{version_or_cond}?")
    end
  end

  def condition(*conds)
    conds.any? do |c|
      if c.is_a? Array
        c.all? { |i| check_version_or_cond(i) }
      else
        check_version_or_cond(c)
      end
    end
  end
end
include SpecCondition
