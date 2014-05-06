class Ridgepole::Delta
  def initialize(delta, options = {})
    @delta = delta
    @options = options
  end

  def migrate
    ActiveRecord::Schema.new.instance_eval(script)
  end

  def script
    buf = StringIO.new

    (@delta[:add] || {}).each do |table_name, attrs|
      append_create_table(table_name, attrs, buf)
    end

    (@delta[:rename] || {}).each do |table_name, attrs|
      append_rename_table(table_name, attrs, buf)
    end

    (@delta[:change] || {}).each do |table_name, attrs|
      append_change(table_name, attrs, buf)
    end

    (@delta[:delete] || {}).each do |table_name, attrs|
      append_drop_table(table_name, attrs, buf)
    end

    buf.string.strip
  end

  def differ?
    not script.empty?
  end

  private

  def append_create_table(table_name, attrs, buf)
    options = attrs[:options] || {}
    definition = attrs[:definition] || {}
    indices = attrs[:indices] || {}

    buf.puts(<<-EOS)
create_table(#{table_name.inspect}, #{options.inspect}) do |t|
    EOS

    definition.each do |column_name, column_attrs|
      column_type = column_attrs.fetch(:type)
      column_options = column_attrs[:options] || {}

      buf.puts(<<-EOS)
  t.#{column_type}(#{column_name.inspect}, #{column_options.inspect})
      EOS
    end

    buf.puts(<<-EOS)
end
    EOS

    indices.each do |index_name, index_attrs|
      append_add_index(table_name, index_name, index_attrs, buf)
    end

    buf.puts
  end

  def append_rename_table(to_table_name, from_table_name, buf)
    buf.puts(<<-EOS)
rename_table(#{from_table_name.inspect}, #{to_table_name.inspect})
    EOS

    buf.puts
  end

  def append_drop_table(table_name, attrs, buf)
    buf.puts(<<-EOS)
drop_table(#{table_name.inspect})
    EOS

    buf.puts
  end

  def append_change(table_name, attrs, buf)
    append_change_definition(table_name, attrs[:definition] || {}, buf)
    append_change_indices(table_name, attrs[:indices] || {}, buf)
    buf.puts
  end

  def append_change_definition(table_name, delta, buf)
    (delta[:add] || {}).each do |column_name, attrs|
      append_add_column(table_name, column_name, attrs, buf)
    end

    (delta[:rename] || {}).each do |column_name, attrs|
      append_rename_column(table_name, column_name, attrs, buf)
    end

    (delta[:change] || {}).each do |column_name, attrs|
      append_change_column(table_name, column_name, attrs, buf)
    end

    (delta[:delete] || {}).each do |column_name, attrs|
      append_remove_column(table_name, column_name, attrs, buf)
    end
  end

  def append_add_column(table_name, column_name, attrs, buf)
    type = attrs.fetch(:type)
    options = attrs[:options] || {}

    buf.puts(<<-EOS)
add_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{options.inspect})
    EOS
  end

  def append_rename_column(table_name, to_column_name, from_column_name, buf)
    buf.puts(<<-EOS)
rename_column(#{table_name.inspect}, #{from_column_name.inspect}, #{to_column_name.inspect})
    EOS
  end

  def append_change_column(table_name, column_name, attrs, buf)
    type = attrs.fetch(:type)
    options = attrs[:options] || {}

    buf.puts(<<-EOS)
change_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{options.inspect})
    EOS
  end

  def append_remove_column(table_name, column_name, attrs, buf)
    buf.puts(<<-EOS)
remove_column(#{table_name.inspect}, #{column_name.inspect})
    EOS
  end

  def append_change_indices(table_name, delta, buf)
    (delta[:add] || {}).each do |index_name, attrs|
      append_add_index(table_name, index_name, attrs, buf)
    end

    (delta[:delete] || {}).each do |index_name, attrs|
      append_remove_index(table_name, index_name, attrs, buf)
    end
  end

  def append_add_index(table_name, index_name, attrs, buf)
    column_name = attrs.fetch(:column_name)
    options = attrs[:options] || {}

    buf.puts(<<-EOS)
add_index(#{table_name.inspect}, #{column_name.inspect}, #{options.inspect})
    EOS
  end

  def append_remove_index(table_name, index_name, attrs, buf)
    column_name = attrs.fetch(:column_name)
    options = attrs[:options] || {}
    target = options[:name] ? {:name => options[:name]} : column_name

    buf.puts(<<-EOS)
remove_index(#{table_name.inspect}, #{target.inspect})
    EOS
  end
end
