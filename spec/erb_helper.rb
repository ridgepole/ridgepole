include ERBh

ERBh.define_method(:i) do |obj|
  if obj.nil? or (obj.respond_to?(:empty?) and obj.empty?)
    @_erbout.sub!(/,\s*\z/, '')
    ''
  else
    obj.modern_inspect_without_brace
  end
end

ERBh.define_method(:cond) do |conds, m, e = nil|
  if condition(*Array(conds))
    m
  else
    e || (m.class.new rescue nil)
  end
end
