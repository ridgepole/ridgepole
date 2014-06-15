class Ridgepole::Diff
  def initialize(options = {})
    @options = options
  end

  def diff(from, to)
    from = (from || {}).dup
    to = (to || {}).dup
    delta = {}

    to.dup.each do |table_name, to_attrs|
      next unless target?(table_name)

      if (from_table_name = (to_attrs[:options] || {}).delete(:from))
        next unless from.has_key?(from_table_name)
        delta[:rename] ||= {}
        delta[:rename][table_name] = from_table_name
        from.delete(from_table_name)
        to.delete(table_name)
      end
    end

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

  def scan_change(table_name, from, to, delta)
    from = (from || {}).dup
    to = (to || {}).dup
    table_delta = {}

    scan_options_change(from[:options], to[:options], table_delta)
    scan_definition_change(from[:definition], to[:definition], table_delta)
    scan_indices_change(from[:indices], to[:indices], table_delta)

    unless table_delta.empty?
      delta[:change] ||= {}
      delta[:change][table_name] = table_delta
    end
  end

  def scan_options_change(from, to, table_delta)
    # XXX: Warn differences of options
  end

  def scan_definition_change(from, to, table_delta)
    from = (from || {}).dup
    to = (to || {}).dup
    definition_delta = {}

    to.dup.each do |column_name, to_attrs|
      if (from_column_name = (to_attrs[:options] || {}).delete(:from))
        next unless from.has_key?(from_column_name)
        definition_delta[:rename] ||= {}
        definition_delta[:rename][column_name] = from_column_name
        from.delete(from_column_name)
        to.delete(column_name)
      end
    end

    priv_column_name = nil

    to.each do |column_name, to_attrs|
      if (from_attrs = from.delete(column_name))
        if from_attrs != to_attrs
          definition_delta[:change] ||= {}
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
    not @options[:tables] or @options[:tables].include?(table_name)
  end
end
