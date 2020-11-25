# frozen_string_literal: true

include ERBh

ERBh.define_method(:i) do |obj|
  if obj.nil? || (obj.respond_to?(:empty?) && obj.empty?)
    @_erbout.sub!(/,\s*\z/, '')
    ''
  elsif obj.is_a?(Hash)
    obj.modern_inspect_without_brace
  else
    obj
  end
end

ERBh.define_method(:cond) do |conds, m, e = nil|
  if condition(*Array(conds))
    m
  else
    e || (begin
      m.class.new
    rescue StandardError
      nil
    end)
  end
end
