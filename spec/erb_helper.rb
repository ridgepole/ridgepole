include ERBh

ERBh.define_method(:i) do |obj|
  if obj.nil? or (obj.respond_to?(:empty?) and obj.empty?)
    @_erbout.sub!(/,\s*\z/, '')
    ''
  else
    obj.modern_inspect_without_brace
  end
end

ERBh.define_method(:add_index) do |table_name, column_name, options|
  if condition(:activerecord_5)
    if options[:length].is_a?(Hash)
      options[:length] = options[:length].symbolize_keys
    end

    @_erbout.sub!(/\bend\s*\z/, '')

    <<-EOS
        t.index #{column_name.inspect}, #{options.modern_inspect_without_brace}
      end
    EOS
  else
    "add_index #{table_name.inspect}, #{column_name.inspect}, #{options.modern_inspect_without_brace}"
  end
end

ERBh.define_method(:unsigned) do |value, *conds|
  conds = [:mysql_awesome_enabled] if conds.empty?

  if condition(*conds)
    {unsigned: value}
  else
    {}
  end
end

ERBh.define_method(:limit) do |value, *conds|
  conds = [:activerecord_4] if conds.empty?

  if condition(*conds)
    {limit: value}
  else
    {}
  end
end
