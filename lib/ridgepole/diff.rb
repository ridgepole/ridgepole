class Ridgepole::Diff
  def initialize(options = {})
    @options = options
    @logger = Ridgepole::Logger.instance
  end

  def diff(from, to, options = {})
    from = (from || {}).deep_dup
    to = (to || {}).deep_dup

    if @options[:reverse]
      from, to = to, from
    end

    delta = {}
    scan_table_rename(from, to, delta)
    # for reverse option
    scan_table_rename(to, from, delta)

    to.each do |table_name, to_attrs|
      next unless target?(table_name)

      if (from_attrs = from.delete(table_name))
        @logger.verbose_info("#   #{table_name}")

        unless (attrs_delta = diff_inspect(from_attrs, to_attrs)).empty?
          @logger.verbose_info(attrs_delta)
        end

        scan_change(table_name, from_attrs, to_attrs, delta)
      else
        delta[:add] ||= {}
        delta[:add][table_name] = to_attrs
      end
    end

    unless @options[:merge]
      from.each do |table_name, from_attrs|
        next unless target?(table_name)

        delta[:delete] ||= {}
        delta[:delete][table_name] = from_attrs
      end
    end

    delta[:execute] = options[:execute]

    Ridgepole::Delta.new(delta, @options)
  end

  private

  def scan_table_rename(from, to, delta, options = {})
    to.dup.each do |table_name, to_attrs|
      next unless target?(table_name)

      if (from_table_name = (to_attrs[:options] || {}).delete(:renamed_from))
        # Already renamed
        next if from[table_name]

        # No existence checking because there is that the table to be read is limited
        #unless from.has_key?(from_table_name)
        #  raise "Table `#{from_table_name}` not found"
        #end

        delta[:rename] ||= {}

        if @options[:reverse]
          delta[:rename][from_table_name] = table_name
        else
          delta[:rename][table_name] = from_table_name
        end

        from.delete(from_table_name)
        to.delete(table_name)
      end
    end
  end

  def scan_change(table_name, from, to, delta)
    from = (from || {}).dup
    to = (to || {}).dup
    table_delta = {}

    scan_options_change(table_name, from[:options], to[:options], table_delta)
    scan_definition_change(from[:definition], to[:definition], from[:indices], table_name, from[:options], table_delta)
    scan_indices_change(from[:indices], to[:indices], to[:definition], table_delta, from[:options], to[:options])
    scan_foreign_keys_change(from[:foreign_keys], to[:foreign_keys], table_delta, @options)

    unless table_delta.empty?
      delta[:change] ||= {}
      delta[:change][table_name] = table_delta
    end
  end

  def scan_options_change(table_name, from, to, table_delta)
    from = (from || {}).dup
    to = (to || {}).dup

    normalize_default_proc_options!(from, to)

    unless from == to
      Ridgepole::Logger.instance.warn("[WARNING] No difference of schema configuration for table `#{table_name}` but table options differ.")
      Ridgepole::Logger.instance.warn("  from: #{from}")
      Ridgepole::Logger.instance.warn("    to: #{to}")
    end
  end

  def scan_definition_change(from, to, from_indices, table_name, table_options, table_delta)
    from = (from || {}).dup
    to = (to || {}).dup
    definition_delta = {}

    scan_column_rename(from, to, definition_delta)
    # for reverse option
    scan_column_rename(to, from, definition_delta)

    if table_options[:id] == false or table_options[:primary_key].is_a?(Array)
      priv_column_name = nil
    else
      priv_column_name = table_options[:primary_key] || 'id'
    end

    to.each do |column_name, to_attrs|
      if (from_attrs = from.delete(column_name))
        normalize_column_options!(from_attrs)
        normalize_column_options!(to_attrs)

        unless compare_column_attrs(from_attrs, to_attrs)
          definition_delta[:change] ||= {}
          to_attrs = fix_change_column_options(table_name, from_attrs, to_attrs)
          definition_delta[:change][column_name] = to_attrs
        end
      else
        definition_delta[:add] ||= {}
        to_attrs[:options] ||= {}

        if priv_column_name
          to_attrs[:options][:after] = priv_column_name
        else
          to_attrs[:options][:first] = true
        end

        definition_delta[:add][column_name] = to_attrs
      end

      priv_column_name = column_name
    end

    if self.class.postgresql?
      added_size = 0
      to.reverse_each.with_index do |(column_name, to_attrs), i|
        if to_attrs[:options].delete(:after)
          if added_size != i
            @logger.warn("[WARNING] PostgreSQL doesn't support adding a new column except for the last position. #{table_name}.#{column_name} will be added to the last.")
          end
          added_size += 1
        end
      end
    end

    unless @options[:merge]
      from.each do |column_name, from_attrs|
        definition_delta[:delete] ||= {}
        definition_delta[:delete][column_name] = from_attrs

        if from_indices
          modified_indices = []

          from_indices.each do |name, attrs|
            if attrs[:column_name].is_a?(Array) && attrs[:column_name].delete(column_name)
              modified_indices << name
            end
          end

          # In PostgreSQL, the index is deleted when the column is deleted
          if @options[:index_removed_drop_column]
            from_indices.reject! do |name, attrs|
              modified_indices.include?(name)
            end
          end

          from_indices.reject! do |name, attrs|
            attrs[:column_name].is_a?(Array) && attrs[:column_name].empty?
          end
        end
      end
    end

    unless definition_delta.empty?
      table_delta[:definition] = definition_delta
    end
  end

  def scan_column_rename(from, to, definition_delta)
    to.dup.each do |column_name, to_attrs|
      if (from_column_name = (to_attrs[:options] || {}).delete(:renamed_from))
        # Already renamed
        next if from[column_name]

        unless from.has_key?(from_column_name)
          raise "Column `#{from_column_name}` not found"
        end

        definition_delta[:rename] ||= {}

        if @options[:reverse]
          definition_delta[:rename][from_column_name] = column_name
        else
          definition_delta[:rename][column_name] = from_column_name
        end

        from.delete(from_column_name)
        to.delete(column_name)
      end
    end
  end

  def scan_indices_change(from, to, to_columns, table_delta, from_table_options, to_table_options)
    from = (from || {}).dup
    to = (to || {}).dup
    indices_delta = {}

    to.each do |index_name, to_attrs|
      if index_name.kind_of?(Array)
        from_index_name, from_attrs = from.find {|name, attrs| attrs[:column_name] == index_name }

        if from_attrs
          from.delete(from_index_name)
          from_attrs[:options].delete(:name)
        end
      else
        from_attrs = from.delete(index_name)
      end

      if from_attrs
        normalize_index_options!(from_attrs[:options])
        normalize_index_options!(to_attrs[:options])

        if from_attrs != to_attrs
          indices_delta[:add] ||= {}
          indices_delta[:add][index_name] = to_attrs

          unless @options[:merge]
            if columns_all_include?(from_attrs[:column_name], to_columns.keys, to_table_options)
              indices_delta[:delete] ||= {}
              indices_delta[:delete][index_name] = from_attrs
            end
          end
        end
      else
        indices_delta[:add] ||= {}
        indices_delta[:add][index_name] = to_attrs
      end
    end

    unless @options[:merge]
      from.each do |index_name, from_attrs|
        if columns_all_include?(from_attrs[:column_name], to_columns.keys, to_table_options)
          indices_delta[:delete] ||= {}
          indices_delta[:delete][index_name] = from_attrs
        end
      end
    end

    unless indices_delta.empty?
      table_delta[:indices] = indices_delta
    end
  end

  def target?(table_name)
    if @options[:tables] and @options[:tables].include?(table_name)
      true
    elsif @options[:ignore_tables] and @options[:ignore_tables].any? {|i| i =~ table_name }
      false
    elsif @options[:tables]
      false
    else
      true
    end
  end

  def normalize_column_options!(attrs)
    opts = attrs[:options]
    opts[:null] = true unless opts.has_key?(:null)
    default_limit = Ridgepole::DefaultsLimit.default_limit(attrs[:type], @options)
    opts.delete(:limit) if opts[:limit] == default_limit

    # XXX: MySQL only?
    if not opts.has_key?(:default)
      opts[:default] = nil
    end

    if @options[:enable_mysql_awesome]
      opts[:unsigned] = false unless opts.has_key?(:unsigned)
    end
  end

  def normalize_index_options!(opts)
    # XXX: MySQL only?
    opts[:using] = :btree unless opts.has_key?(:using)
    opts[:unique] = false unless opts.has_key?(:unique)
  end

  def columns_all_include?(expected_columns, actual_columns, table_options)
    unless expected_columns.is_a?(Array)
      return true
    end

    if table_options[:id] != false and not table_options[:primary_key].is_a?(Array)
      actual_columns = actual_columns + [(table_options[:primary_key] || 'id').to_s]
    end

    expected_columns.all? {|i| actual_columns.include?(i) }
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

  # XXX: MySQL only?
  # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L760
  # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/abstract/schema_creation.rb#L102
  def fix_change_column_options(table_name, from_attrs, to_attrs)
    # default: 0, null: false -> default: nil, null: false | default: nil
    # default: 0, null: false ->               null: false | default: nil
    # default: 0, null: false -> default: nil, null: true  | default: nil, null: true
    # default: 0, null: false ->               null: true  | default: nil, null: true
    # default: 0, null: true  -> default: nil, null: true  | default: nil
    # default: 0, null: true  ->               null: true  | default: nil
    # default: 0, null: true  -> default: nil, null: false | default: nil, null: false (`default: nil` is ignored)
    # default: 0, null: true ->                null: false | default: nil, null: false (`default: nil` is ignored)

    if from_attrs[:options][:default] != to_attrs[:options][:default] and from_attrs[:options][:null] == to_attrs[:options][:null]
      to_attrs = to_attrs.deep_dup
      to_attrs[:options].delete(:null)
    end

    if to_attrs[:options][:default] == nil and to_attrs[:options][:null] == false
      Ridgepole::Logger.instance.warn("[WARNING] Table `#{table_name}`: `default: nil` is ignored when `null: false`. Please apply twice")
    end

    to_attrs
  end

  def compare_column_attrs(attrs1, attrs2)
    attrs1 = attrs1.merge(:options => attrs1.fetch(:options, {}).dup)
    attrs2 = attrs2.merge(:options => attrs2.fetch(:options, {}).dup)
    normalize_default_proc_options!(attrs1[:options], attrs2[:options])
    attrs1 == attrs2
  end

  def normalize_default_proc_options!(opts1, opts2)
    if opts1[:default].kind_of?(Proc) and opts2[:default].kind_of?(Proc)
      opts1[:default] = opts1[:default].call
      opts2[:default] = opts2[:default].call
    end
  end

  def diff_inspect(obj1, obj2, options = {})
    diffy = Diffy::Diff.new(
      obj1.pretty_inspect,
      obj2.pretty_inspect,
      :diff => '-u'
    )

    diffy.to_s(:text).gsub(/\s+\z/m, '')
  end

  def self.postgresql?
    defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) && ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  end
end
