class String
  def undent
    min_space_num = self.split("\n").delete_if {|s| s =~ /^\s*$/ }.map {|s| (s[/^\s+/] || '').length }.min

    if min_space_num and min_space_num > 0
      gsub(/^[ \t]{,#{min_space_num}}/, '')
    else
      self
    end
  end
end
