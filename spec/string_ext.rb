class String
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

  def gsub_surely(pattern, replace)
    old_str = self.dup
    new_str = self.gsub(pattern, replace)
    raise 'must not happen' if old_str == new_str
    new_str
  end

  def delete_empty_lines
    self.each_line.select {|line|
      line !~ /\A\s*\Z/
    }.join
  end
end
