class String
  # TODO: must be remove
  def delete_create_table(name)
    new_def = []
    in_block = false

    self.each_line do |line|
      if line =~ /\A\s*create_table\s+"#{name}"/
        in_block = true
      elsif in_block and line =~ /\A\s*end\s*\Z/
        in_block = false
      elsif not in_block
        new_def << line
      end
    end

    new_def = new_def.join
    raise 'must not happen' if new_def =~ /^\s*create_table\s+"#{name}"/m
    new_def.delete_add_index(name)
  end

  # TODO: must be remove
  def delete_add_index(name, columns = nil)
    new_def = []
    in_block = false

    args = name.inspect
    args << ',\\s*\\[' + columns.map {|i| i.inspect }.join(',\\s*') + '\\]' if columns

    self.each_line do |line|
      if line !~ /\A\s*add_index\s+#{args}/
        new_def << line
      end
    end

    new_def = new_def.join
    raise 'must not happen' if new_def =~ /^\s*add_index\s+#{args}/m
    new_def
  end
end
