class Ridgepole::Delta
  SCRIPT_NAME = '<Schema>'

  def initialize(delta, options = {})
    @delta = delta
    @options = options
    @logger = Ridgepole::Logger.instance
  end

  def migrate(options = {})
    if log_file = @options[:log_file]
      result = ActiveRecord::Migration.record_time do
        migrate0(options)
      end

      open(log_file, 'wb') {|f| f.puts JSON.pretty_generate(result) }
      result
    else
      migrate0(options)
    end
  end

  def script
    buf = StringIO.new
    buf_for_add_fk = StringIO.new
    buf_for_remove_fk = StringIO.new

    (@delta[:add] || {}).each do |table_name, attrs|
      append_create_table(table_name, attrs, buf, buf_for_add_fk)
    end

    (@delta[:rename] || {}).each do |table_name, attrs|
      append_rename_table(table_name, attrs, buf)
    end

    (@delta[:change] || {}).each do |table_name, attrs|
      append_change(table_name, attrs, buf, buf_for_add_fk, buf_for_remove_fk)
    end

    (@delta[:delete] || {}).each do |table_name, attrs|
      append_drop_table(table_name, attrs, buf)
    end

    (buf_for_remove_fk.string.strip + "\n\n" + buf.string.strip + "\n\n" + buf_for_add_fk.string.strip).strip
  end

  def differ?
    not script.empty? or not delta_execute.empty?
  end

  private

  def migrate0(options = {})
    migrated = false
    out = nil

    if options[:noop]
      disable_logging_orig = ActiveRecord::Migration.disable_logging

      begin
        ActiveRecord::Migration.disable_logging = true
        buf = StringIO.new

        callback = proc do |sql, name|
          buf.puts sql if sql =~ /\A(CREATE|ALTER|DROP|RENAME)\b/i
        end

        eval_script_block = proc do
          Ridgepole::ExecuteExpander.without_operation(callback) do
            migrated = eval_script(script, options.merge(:out => buf))
          end
        end

        if options[:alter_extra]
          Ridgepole::ExecuteExpander.with_alter_extra(options[:alter_extra]) do
            eval_script_block.call
          end
        else
          eval_script_block.call
        end

        out = buf.string.strip
      ensure
        ActiveRecord::Migration.disable_logging = disable_logging_orig
      end
    elsif options[:external_script]
      Ridgepole::ExecuteExpander.with_script(options[:external_script], Ridgepole::Logger.instance) do
        migrated = eval_script(script, options)
      end
    elsif options[:alter_extra]
      Ridgepole::ExecuteExpander.with_alter_extra(options[:alter_extra]) do
        migrated = eval_script(script, options)
      end
    else
      migrated = eval_script(script, options)
    end

    [migrated, out]
  end

  def eval_script(script, options = {})
    execute_count = 0

    begin
      with_pre_post_query(options) do
        unless script.empty?
          ActiveRecord::Schema.new.instance_eval(script, SCRIPT_NAME, 1)
        end

        execute_count = execute_sqls(options)
      end
    rescue => e
      raise_exception(script, e)
    end

    not script.empty? or execute_count.nonzero?
  end

  def execute_sqls(options = {})
    es = @delta[:execute] || []
    out = options[:out] || $stdout
    execute_count = 0

    es.each do |exec|
      sql, cond = exec.values_at(:sql, :condition)
      executable = false

      begin
        executable = cond.nil? || cond.call(ActiveRecord::Base.connection)
      rescue => e
        errmsg = "[WARN] `#{sql}` is not executed: #{e.message}"

        if @options[:debug]
          errmsg = ([errmsg] + e.backtrace).join("\n\tfrom ")
        end

        Ridgepole::Logger.instance.warn(errmsg)

        executable = false
      end

      next unless executable

      if options[:noop]
        out.puts(sql.strip_heredoc)
      else
        @logger.info(sql.strip_heredoc)
        ActiveRecord::Base.connection.execute(sql)
      end

      execute_count += 1
    end

    return execute_count
  end

  def with_pre_post_query(options = {})
    out = options[:out] || $stdout

    if (pre_query = @options[:pre_query])
      if options[:noop]
        out.puts(pre_query)
      else
        ActiveRecord::Base.connection.execute(pre_query)
      end
    end

    retval = yield

    if (post_query = @options[:post_query])
      if options[:noop]
        out.puts(post_query)
      else
        ActiveRecord::Base.connection.execute(post_query)
      end
    end

    return retval
  end

  def raise_exception(script, org)
    lines = script.each_line
    digit_number = (lines.count + 1).to_s.length
    err_num = detect_error_line(org)

    errmsg = lines.with_index.map {|l, i|
      line_num = i + 1
      prefix = (line_num == err_num) ? '* ' : '  '
      "#{prefix}%*d: #{l}" % [digit_number, line_num]
    }

    if err_num > 0
      from = err_num - 6
      from = 0 if from < 0
      to = err_num + 4
      errmsg = errmsg.slice(from..to)
    end

    e = RuntimeError.new(org.message + "\n" + errmsg.join)
    e.set_backtrace(org.backtrace)
    raise e
  end

  def detect_error_line(e)
    rgx = /\A#{Regexp.escape(SCRIPT_NAME)}:(\d+):/
    line = e.backtrace.find {|i| i =~ rgx }

    if line and (m = rgx.match(line))
      m[1].to_i
    else
      0
    end
  end

  def append_create_table(table_name, attrs, buf, buf_for_fk)
    options = attrs[:options] || {}
    options[:options] ||= @options[:table_options] if @options[:table_options]
    definition = attrs[:definition] || {}
    indices = attrs[:indices] || {}

    buf.puts(<<-EOS)
create_table(#{table_name.inspect}, #{inspect_options_include_default_proc(options)}) do |t|
    EOS

    definition.each do |column_name, column_attrs|
      column_type = column_attrs.fetch(:type)
      column_options = column_attrs[:options] || {}
      normalize_limit(column_type, column_options)

      buf.puts(<<-EOS)
  t.#{column_type}(#{column_name.inspect}, #{inspect_options_include_default_proc(column_options)})
      EOS
    end

    buf.puts(<<-EOS)
end
    EOS

    unless indices.empty?
      append_change_table(table_name, buf) do
        indices.each do |index_name, index_attrs|
          append_add_index(table_name, index_name, index_attrs, buf)
        end
      end
    end

    unless (foreign_keys = attrs[:foreign_keys] || {}).empty?
      foreign_keys.each do |foreign_key_name, foreign_key_attrs|
        append_add_foreign_key(table_name, foreign_key_name, foreign_key_attrs, buf_for_fk, @options)
      end
    end

    buf.puts
    buf_for_fk.puts
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

  def append_change(table_name, attrs, buf, buf_for_add_fk, buf_for_remove_fk)
    definition = attrs[:definition] || {}
    indices = attrs[:indices] || {}
    foreign_keys = attrs[:foreign_keys] || {}

    if not definition.empty? or not indices.empty?
      append_change_table(table_name, buf) do
        append_change_definition(table_name, definition, buf)
        append_change_indices(table_name, indices, buf)
      end
    end

    unless foreign_keys.empty?
      append_change_foreign_keys(table_name, foreign_keys, buf_for_add_fk, buf_for_remove_fk, @options)
    end

    buf.puts
    buf_for_add_fk.puts
    buf_for_remove_fk.puts
  end

  def append_change_table(table_name, buf)
    buf.puts "change_table(#{table_name.inspect}, {:bulk => true}) do |t|" if @options[:bulk_change]
    yield
    buf.puts 'end' if @options[:bulk_change]
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
    normalize_limit(type, options)

    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.column(#{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      EOS
    else
      buf.puts(<<-EOS)
add_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      EOS
    end
  end

  def append_rename_column(table_name, to_column_name, from_column_name, buf)
    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.rename(#{from_column_name.inspect}, #{to_column_name.inspect})
      EOS
    else
      buf.puts(<<-EOS)
rename_column(#{table_name.inspect}, #{from_column_name.inspect}, #{to_column_name.inspect})
      EOS
    end
  end

  def append_change_column(table_name, column_name, attrs, buf)
    type = attrs.fetch(:type)
    options = attrs[:options] || {}

    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.change(#{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      EOS
    else
      buf.puts(<<-EOS)
change_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      EOS
    end
  end

  def append_remove_column(table_name, column_name, attrs, buf)
    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.remove(#{column_name.inspect})
      EOS
    else
      buf.puts(<<-EOS)
remove_column(#{table_name.inspect}, #{column_name.inspect})
      EOS
    end
  end

  def append_change_indices(table_name, delta, buf)
    (delta[:delete] || {}).each do |index_name, attrs|
      append_remove_index(table_name, index_name, attrs, buf)
    end

    (delta[:add] || {}).each do |index_name, attrs|
      append_add_index(table_name, index_name, attrs, buf)
    end
  end

  def append_add_index(table_name, index_name, attrs, buf)
    column_name = attrs.fetch(:column_name)
    options = attrs[:options] || {}

    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.index(#{column_name.inspect}, #{options.inspect})
      EOS
    else
      buf.puts(<<-EOS)
add_index(#{table_name.inspect}, #{column_name.inspect}, #{options.inspect})
      EOS
    end
  end

  def append_remove_index(table_name, index_name, attrs, buf)
    column_name = attrs.fetch(:column_name)
    options = attrs[:options] || {}
    target = options[:name] ? {:name => options[:name]} : column_name

    if @options[:bulk_change]
      buf.puts(<<-EOS)
  t.remove_index(#{target.inspect})
      EOS
    else
      buf.puts(<<-EOS)
remove_index(#{table_name.inspect}, #{target.inspect})
      EOS
    end
  end

  def append_change_foreign_keys(table_name, delta, buf_for_add, buf_for_remove, options)
    (delta[:delete] || {}).each do |foreign_key_name, attrs|
      append_remove_foreign_key(table_name, foreign_key_name, attrs, buf_for_remove, options)
    end

    (delta[:add] || {}).each do |foreign_key_name, attrs|
      append_add_foreign_key(table_name, foreign_key_name, attrs, buf_for_add, options)
    end
  end

  def append_add_foreign_key(table_name, foreign_key_name, attrs, buf, options)
    to_table = attrs.fetch(:to_table)
    attrs_options = attrs[:options] || {}

    buf.puts(<<-EOS)
add_foreign_key(#{table_name.inspect}, #{to_table.inspect}, #{attrs_options.inspect})
    EOS
  end

  def append_remove_foreign_key(table_name, foreign_key_name, attrs, buf, options)
    attrs_options = attrs[:options] || {}
    target = {:name => attrs_options.fetch(:name)}

    buf.puts(<<-EOS)
remove_foreign_key(#{table_name.inspect}, #{target.inspect})
    EOS
  end

  def delta_execute
    @delta[:execute] || []
  end

  def normalize_limit(column_type, column_options)
    default_limit = Ridgepole::DefaultsLimit.default_limit(column_type, @options)
    column_options[:limit] ||= default_limit if default_limit
  end

  def inspect_options_include_default_proc(options)
    options = options.dup

    if options[:default].kind_of?(Proc)
      proc_default = options.delete(:default)
      proc_default = ":default=>proc{#{proc_default.call.inspect}}"
      options_inspect = options.inspect
      options_inspect.sub!(/\}\z/, '')
      options_inspect << ', ' if options_inspect !~ /\{\z/
      options_inspect << proc_default << '}'
      options_inspect
    else
      options.inspect
    end
  end
end
