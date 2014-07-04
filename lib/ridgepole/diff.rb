class Ridgepole::Diff
  def initialize(options = {})
    @options = options
  end

  def diff(from, to)
    from = (from || {}).dup
    to = (to || {}).dup

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

    Ridgepole::Delta.new(delta, @options)
  end

  private

  def scan_table_rename(from, to, delta, options = {})
    to.dup.each do |table_name, to_attrs|
      next unless target?(table_name)

      if (from_table_name = (to_attrs[:options] || {}).delete(:rename_from))
        # Already renamed
        next if to[from_table_name]

        unless from.has_key?(from_table_name)
          raise "Table `#{from_table_name}` not found"
        end

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
    scan_definition_change(from[:definition], to[:definition], table_delta)
    scan_indices_change(from[:indices], to[:indices], table_delta)

    unless table_delta.empty?
      delta[:change] ||= {}
      delta[:change][table_name] = table_delta
    end
  end

  def scan_options_change(table_name, from, to, table_delta)
    unless from == to
      Ridgepole::Logger.instance.warn("[WARNING] Table `#{table_name}` options cannot be changed")
    end
  end

  def scan_definition_change(from, to, table_delta)
    from = (from || {}).dup
    to = (to || {}).dup
    definition_delta = {}

    scan_column_rename(from, to, definition_delta)
    # for reverse option
    scan_column_rename(to, from, definition_delta)

    priv_column_name = nil

    to.each do |column_name, to_attrs|
      if (from_attrs = from.delete(column_name))
        normalize_column_options!(from_attrs[:options])
        normalize_column_options!(to_attrs[:options])

        if from_attrs != to_attrs
          definition_delta[:change] ||= {}
          definition_delta[:change][column_name] = to_attrs
        end
      else
        definition_delta[:add] ||= {}
        to_attrs[:options] ||= {}

        unless @options[:merge]
          if priv_column_name
            to_attrs[:options][:after] = priv_column_name
          else
            to_attrs[:options][:first] = true
          end
        end

        definition_delta[:add][column_name] = to_attrs
      end

      priv_column_name = column_name
    end

    unless @options[:merge]
      from.each do |column_name, from_attrs|
        definition_delta[:delete] ||= {}
        definition_delta[:delete][column_name] = from_attrs
      end
    end

    unless definition_delta.empty?
      table_delta[:definition] = definition_delta
    end
  end

  def scan_column_rename(from, to, definition_delta)
    to.dup.each do |column_name, to_attrs|
      if (from_column_name = (to_attrs[:options] || {}).delete(:rename_from))
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

  def scan_indices_change(from, to, table_delta)
    from = (from || {}).dup
    to = (to || {}).dup
    indices_delta = {}

    to.each do |index_name, to_attrs|
      if (from_attrs = from.delete(index_name))
        if from_attrs != to_attrs
          indices_delta[:add] ||= {}
          indices_delta[:add][index_name] = to_attrs

          unless @options[:merge]
            indices_delta[:delete] ||= {}
            indices_delta[:delete][index_name] = from_attrs
          end
        end
      else
        indices_delta[:add] ||= {}
        indices_delta[:add][index_name] = to_attrs
      end
    end

    unless @options[:merge]
      from.each do |index_name, from_attrs|
        indices_delta[:delete] ||= {}
        indices_delta[:delete][index_name] = from_attrs
      end
    end

    unless indices_delta.empty?
      table_delta[:indices] = indices_delta
    end
  end

  def target?(table_name)
    if @options[:ignore_tables] and @options[:ignore_tables].any? {|i| i =~ table_name }
      false
    elsif @options[:tables] and not @options[:tables].include?(table_name)
      false
    else
      true
    end
  end

  def normalize_column_options!(opts)
    opts[:null] = true unless opts.has_key?(:null)

    unless @options[:disable_mysql_unsigned]
      opts[:unsigned] = false unless opts.has_key?(:unsigned)
    end
  end
end
