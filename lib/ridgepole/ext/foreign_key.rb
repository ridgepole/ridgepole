class Ridgepole::ForeignKey
  class << self
    def init
      require 'foreigner'

      ActiveSupport.on_load :active_record do
        Foreigner.load
      end

      Ridgepole::DSLParser::Context.include_module(Ridgepole::ForeignKey::DSL)
    end

    def check_orphan_foreign_key(definition)
      definition.each do |table_name, attrs|
        if attrs[:foreign_keys] and not attrs[:definition]
          raise "Table `#{table_name}` to create the foreign key is not defined: #{attrs[:foreign_keys].keys.join(',')}"
        end
      end
    end

    def scan_foreign_keys_change(from, to, table_delta, options)
      from = (from || {}).dup
      to = (to || {}).dup
      foreign_keys_delta = {}

      to.each do |foreign_key_name, to_attrs|
        from_attrs = from.delete(foreign_key_name)

        if from_attrs
          if from_attrs != to_attrs
            foreign_keys_delta[:add] ||= {}
            foreign_keys_delta[:add][foreign_key_name] = to_attrs

            unless options[:merge]
              foreign_keys_delta[:delete] ||= {}
              foreign_keys_delta[:delete][foreign_key_name] = from_attrs
            end
          end
        else
          foreign_keys_delta[:add] ||= {}
          foreign_keys_delta[:add][foreign_key_name] = to_attrs
        end
      end

      unless options[:merge]
        from.each do |foreign_key_name, from_attrs|
          foreign_keys_delta[:delete] ||= {}
          foreign_keys_delta[:delete][foreign_key_name] = from_attrs
        end
      end

      unless foreign_keys_delta.empty?
        table_delta[:foreign_keys] = foreign_keys_delta
      end
    end

    def append_change_foreign_keys(table_name, delta, buf, options)
      (delta[:delete] || {}).each do |foreign_key_name, attrs|
        append_remove_foreign_key(table_name, foreign_key_name, attrs, buf, options)
      end

      (delta[:add] || {}).each do |foreign_key_name, attrs|
        append_add_foreign_key(table_name, foreign_key_name, attrs, buf, options)
      end
    end

    private

    def append_add_foreign_key(table_name, foreign_key_name, attrs, buf, options)
      to_table = attrs.fetch(:to_table)
      attrs_options = attrs[:options] || {}

      if options[:bulk_change]
        buf.puts(<<-EOS)
    t.foreign_key(#{to_table.inspect}, #{attrs_options.inspect})
        EOS
      else
        buf.puts(<<-EOS)
  add_foreign_key(#{table_name.inspect}, #{to_table.inspect}, #{attrs_options.inspect})
        EOS
      end
    end

    def append_remove_foreign_key(table_name, foreign_key_name, attrs, buf, options)
      attrs_options = attrs[:options] || {}
      target = {:name => attrs_options.fetch(:name)}

      if options[:bulk_change]
        buf.puts(<<-EOS)
    t.remove_foreign_key(#{target.inspect})
        EOS
      else
        buf.puts(<<-EOS)
  remove_foreign_key(#{table_name.inspect}, #{target.inspect})
        EOS
      end
    end
  end # of class methods

  module DSL
    def add_foreign_key(from_table, to_table, options = {})
      unless options[:name]
        raise "Foreign key name in `#{from_table}` is undefined"
      end

      from_table = from_table.to_s
      to_table = to_table.to_s
      options[:name] = options[:name].to_s
      @__definition[from_table] ||= {}
      @__definition[from_table][:foreign_keys] ||= {}
      idx = options[:name]

      if @__definition[from_table][:foreign_keys][idx]
        raise "Foreign Key `#{from_table}(#{idx})` already defined"
      end

      @__definition[from_table][:foreign_keys][idx] = {
        :to_table => to_table,
        :options => options,
      }
    end
  end
end
