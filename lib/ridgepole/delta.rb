module Ridgepole
  class Delta
    SCRIPT_NAME = '<Schema>'.freeze

    def initialize(delta, options = {})
      @delta = delta
      @options = options
      @logger = Ridgepole::Logger.instance
    end

    def migrate(options = {})
      log_file = @options[:log_file]

      if log_file
        result = ActiveRecord::Migration.record_time do
          migrate0(options)
        end

        File.open(log_file, 'wb') { |f| f.puts JSON.pretty_generate(result) }
        result
      else
        migrate0(options)
      end
    end

    def script
      buf = StringIO.new
      pre_buf_for_fk = StringIO.new
      post_buf_for_fk = StringIO.new

      (@delta[:add] || {}).each do |table_name, attrs|
        append_create_table(table_name, attrs, buf, post_buf_for_fk)
      end

      (@delta[:rename] || {}).each do |table_name, attrs|
        append_rename_table(table_name, attrs, buf)
      end

      (@delta[:change] || {}).each do |table_name, attrs|
        append_change(table_name, attrs, buf, pre_buf_for_fk, post_buf_for_fk)
      end

      (@delta[:delete] || {}).each do |table_name, attrs|
        append_drop_table(table_name, attrs, buf)
      end

      [
        pre_buf_for_fk,
        buf,
        post_buf_for_fk
      ].map { |b| b.string.strip }.join("\n\n").strip
    end

    def differ?
      !script.empty? || !delta_execute.empty?
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

          callback = proc do |sql, _name|
            buf.puts sql if sql =~ /\A(CREATE|ALTER|DROP|RENAME)\b/i
          end

          eval_script_block = proc do
            Ridgepole::ExecuteExpander.without_operation(callback) do
              migrated = eval_script(script, options.merge(out: buf))
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
          ActiveRecord::Schema.new.instance_eval(script, SCRIPT_NAME, 1) unless script.empty?

          execute_count = execute_sqls(options)
        end
      rescue StandardError => e
        raise_exception(script, e)
      end

      !script.empty? || execute_count.nonzero?
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
        rescue StandardError => e
          errmsg = "[WARN] `#{sql}` is not executed: #{e.message}"

          errmsg = ([errmsg] + e.backtrace).join("\n\tfrom ") if @options[:debug]

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

      execute_count
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

      retval
    end

    def raise_exception(script, org)
      lines = script.each_line
      digit_number = (lines.count + 1).to_s.length
      err_num = detect_error_line(org)

      errmsg = lines.with_index.map do |l, i|
        line_num = i + 1
        prefix = line_num == err_num ? '* ' : '  '
        format("#{prefix}%*d: #{l}", digit_number, line_num)
      end

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

    def detect_error_line(exception)
      rgx = /\A#{Regexp.escape(SCRIPT_NAME)}:(\d+):/
      line = exception.backtrace.find { |i| i =~ rgx }

      if line && (m = rgx.match(line))
        m[1].to_i
      else
        0
      end
    end

    def append_create_table(table_name, attrs, buf, post_buf_for_fk)
      options = attrs[:options] || {}
      definition = attrs[:definition] || {}
      indices = attrs[:indices] || {}

      buf.puts(<<-RUBY)
create_table(#{table_name.inspect}, #{inspect_options_include_default_proc(options)}) do |t|
    RUBY

      definition.each do |column_name, column_attrs|
        column_type = column_attrs.fetch(:type)
        column_options = column_attrs[:options] || {}
        normalize_limit(column_type, column_options)

        buf.puts(<<-RUBY)
  t.column(#{column_name.inspect}, :#{column_type.to_s.inspect}, #{inspect_options_include_default_proc(column_options)})
      RUBY
      end

      if @options[:create_table_with_index] && !indices.empty?
        indices.each do |index_name, index_attrs|
          append_add_index(table_name, index_name, index_attrs, buf, true)
        end
      end

      buf.puts(<<-RUBY)
  end
      RUBY

      if !(@options[:create_table_with_index]) && !indices.empty?
        append_change_table(table_name, buf) do
          indices.each do |index_name, index_attrs|
            append_add_index(table_name, index_name, index_attrs, buf)
          end
        end
      end

      unless (foreign_keys = attrs[:foreign_keys] || {}).empty?
        foreign_keys.each do |_, foreign_key_attrs|
          append_add_foreign_key(table_name, foreign_key_attrs, post_buf_for_fk, @options)
        end
      end

      buf.puts
      post_buf_for_fk.puts
    end

    def append_rename_table(to_table_name, from_table_name, buf)
      buf.puts(<<-RUBY)
rename_table(#{from_table_name.inspect}, #{to_table_name.inspect})
    RUBY

      buf.puts
    end

    def append_drop_table(table_name, _attrs, buf)
      buf.puts(<<-RUBY)
drop_table(#{table_name.inspect})
    RUBY

      buf.puts
    end

    def append_change_table_options(table_name, table_options, buf)
      # XXX: MySQL only
      buf.puts(<<-RUBY)
execute "ALTER TABLE #{ActiveRecord::Base.connection.quote_table_name(table_name)} #{table_options}"
    RUBY

      buf.puts
    end

    def append_change_table_comment(table_name, table_comment, buf)
      comment_literal = "COMMENT=#{ActiveRecord::Base.connection.quote(table_comment)}"
      append_change_table_options(table_name, comment_literal, buf)
    end

    def append_change(table_name, attrs, buf, pre_buf_for_fk, post_buf_for_fk)
      definition = attrs[:definition] || {}
      primary_key_definition = attrs[:primary_key_definition] || {}
      indices = attrs[:indices] || {}
      foreign_keys = attrs[:foreign_keys] || {}
      table_options = attrs[:table_options]
      table_comment = attrs[:table_comment]

      if !definition.empty? || !indices.empty? || !primary_key_definition.empty?
        append_change_table(table_name, buf) do
          append_delete_indices(table_name, indices, buf)
          append_change_definition(table_name, definition, buf)
          append_change_definition(table_name, primary_key_definition, buf)
          append_add_indices(table_name, indices, buf)
        end
      end

      append_change_foreign_keys(table_name, foreign_keys, pre_buf_for_fk, post_buf_for_fk, @options) unless foreign_keys.empty?

      append_change_table_options(table_name, table_options, buf) if table_options

      append_change_table_comment(table_name, table_comment, buf) if table_comment

      buf.puts
      pre_buf_for_fk.puts
      post_buf_for_fk.puts
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
        buf.puts(<<-RUBY)
  t.column(#{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      RUBY
      else
        buf.puts(<<-RUBY)
add_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      RUBY
      end
    end

    def append_rename_column(table_name, to_column_name, from_column_name, buf)
      if @options[:bulk_change]
        buf.puts(<<-RUBY)
  t.rename(#{from_column_name.inspect}, #{to_column_name.inspect})
      RUBY
      else
        buf.puts(<<-RUBY)
rename_column(#{table_name.inspect}, #{from_column_name.inspect}, #{to_column_name.inspect})
      RUBY
      end
    end

    def append_change_column(table_name, column_name, attrs, buf)
      type = attrs.fetch(:type)
      options = attrs[:options] || {}

      # Fix for https://github.com/rails/rails/commit/7f0567b43b73b1bd1a16bfac9cd32fcbf1321b51
      if Ridgepole::ConnectionAdapters.mysql? && ActiveRecord::VERSION::STRING !~ /\A5\.0\./
        options[:comment] = nil unless options.key?(:comment)
      end

      if @options[:bulk_change]
        buf.puts(<<-RUBY)
  t.change(#{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      RUBY
      else
        buf.puts(<<-RUBY)
change_column(#{table_name.inspect}, #{column_name.inspect}, #{type.inspect}, #{inspect_options_include_default_proc(options)})
      RUBY
      end
    end

    def append_remove_column(table_name, column_name, _attrs, buf)
      if @options[:bulk_change]
        buf.puts(<<-RUBY)
  t.remove(#{column_name.inspect})
      RUBY
      else
        buf.puts(<<-RUBY)
remove_column(#{table_name.inspect}, #{column_name.inspect})
      RUBY
      end
    end

    def append_add_indices(table_name, delta, buf)
      (delta[:add] || {}).each do |index_name, attrs|
        append_add_index(table_name, index_name, attrs, buf)
      end
    end

    def append_delete_indices(table_name, delta, buf)
      (delta[:delete] || {}).each do |index_name, attrs|
        append_remove_index(table_name, index_name, attrs, buf)
      end
    end

    def append_add_index(table_name, _index_name, attrs, buf, force_bulk_change = false)
      column_name = attrs.fetch(:column_name)
      options = attrs[:options] || {}

      if force_bulk_change || @options[:bulk_change]
        buf.puts(<<-RUBY)
  t.index(#{column_name.inspect}, #{options.inspect})
      RUBY
      else
        buf.puts(<<-RUBY)
add_index(#{table_name.inspect}, #{column_name.inspect}, #{options.inspect})
      RUBY
      end
    end

    def append_remove_index(table_name, _index_name, attrs, buf)
      column_name = attrs.fetch(:column_name)
      options = attrs[:options] || {}
      target = options[:name] ? { name: options[:name] } : column_name

      if @options[:bulk_change]
        buf.puts(<<-RUBY)
  t.remove_index(#{target.inspect})
      RUBY
      else
        buf.puts(<<-RUBY)
remove_index(#{table_name.inspect}, #{target.inspect})
      RUBY
      end
    end

    def append_change_foreign_keys(table_name, delta, pre_buf_for_fk, post_buf_for_fk, options)
      (delta[:delete] || {}).each do |_, attrs|
        append_remove_foreign_key(table_name, attrs, pre_buf_for_fk, options)
      end

      (delta[:add] || {}).each do |_, attrs|
        append_add_foreign_key(table_name, attrs, post_buf_for_fk, options)
      end
    end

    def append_add_foreign_key(table_name, attrs, buf, _options)
      to_table = attrs.fetch(:to_table)
      attrs_options = attrs[:options] || {}

      buf.puts(<<-RUBY)
add_foreign_key(#{table_name.inspect}, #{to_table.inspect}, #{attrs_options.inspect})
    RUBY
    end

    def append_remove_foreign_key(table_name, attrs, buf, _options)
      attrs_options = attrs[:options] || {}
      fk_name = attrs_options[:name]

      target = if fk_name
                 { name: fk_name }
               else
                 attrs.fetch(:to_table)
               end

      buf.puts(<<-RUBY)
remove_foreign_key(#{table_name.inspect}, #{target.inspect})
    RUBY
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

      if options[:default].is_a?(Proc)
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
end
