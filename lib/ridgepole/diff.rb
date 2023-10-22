# frozen_string_literal: true

module Ridgepole
  class Diff
    PRIMARY_KEY_OPTIONS = %i[id limit default null precision scale collation unsigned].freeze

    def initialize(options = {})
      @options = options
      @logger = Ridgepole::Logger.instance
    end

    def diff(from, to, options = {})
      from = (from || {}).deep_dup
      to = (to || {}).deep_dup

      check_table_existence(to)

      delta = {}
      relation_info = {}

      scan_table_rename(from, to, delta)

      to.each do |table_name, to_attrs|
        collect_relation_info!(table_name, to_attrs, relation_info)

        next unless target?(table_name)

        if (from_attrs = from.delete(table_name))
          @logger.verbose_info("#   #{table_name}")

          unless (attrs_delta = diff_inspect(from_attrs, to_attrs)).empty?
            @logger.verbose_info(attrs_delta)
          end

          scan_change(table_name, from_attrs, to_attrs, delta)
        else
          delta[:add] ||= {}
          delta[:add][table_name] = to_attrs
        end
      end

      scan_relation_info(relation_info)

      if !@options[:merge] && @options[:force_drop_table]
        from.each do |table_name, from_attrs|
          next unless target?(table_name)

          delta[:delete] ||= {}
          delta[:delete][table_name] = from_attrs

          foreign_keys = from_attrs.fetch(:foreign_keys, {})
          next if foreign_keys.empty?

          table_delta = {}
          scan_foreign_keys_change(foreign_keys, {}, table_delta, @options)
          delta[:change] ||= {}
          delta[:change][table_name] = table_delta
        end
      end

      delta[:execute] = options[:execute]

      Ridgepole::Delta.new(delta, @options)
    end

    private

    def scan_table_rename(from, to, delta, _options = {})
      to.dup.each do |table_name, to_attrs|
        next unless target?(table_name)

        next unless (from_table_name = (to_attrs[:options] || {}).delete(:renamed_from))

        from_table_name = from_table_name.to_s if from_table_name

        # Already renamed
        if from[table_name]
          @logger.warn("[WARNING] The table `#{from_table_name}` has already been renamed to the table `#{table_name}`.")
          next
        end

        unless from[from_table_name]
          @logger.warn("[WARNING] The table `#{from_table_name}` to be renamed does not exist.")
          next
        end

        delta[:rename] ||= {}
        delta[:rename][table_name] = from_table_name

        from.delete(from_table_name)
        to.delete(table_name)
      end
    end

    def scan_change(table_name, from, to, delta)
      from = (from || {}).dup
      to = (to || {}).dup
      table_delta = {}

      scan_options_change(table_name, from[:options], to[:options], table_delta)
      scan_definition_change(from[:definition], to[:definition], from[:indices], table_name, from[:options], table_delta)
      scan_indices_change(from[:indices], to[:indices], to[:definition], table_delta, from[:options], to[:options])
      scan_foreign_keys_change(from[:foreign_keys], to[:foreign_keys], table_delta, @options)
      scan_check_constraints_change(from[:check_constraints], to[:check_constraints], table_delta)
      scan_exclusion_constraints_change(from[:exclusion_constraints], to[:exclusion_constraints], table_delta)
      scan_unique_constraints_change(from[:unique_constraints], to[:unique_constraints], table_delta)

      unless table_delta.empty?
        delta[:change] ||= {}
        delta[:change][table_name] = table_delta
      end
    end

    def scan_options_change(table_name, from, to, table_delta)
      from = (from || {}).dup
      to = (to || {}).dup

      normalize_default_proc_options!(from, to)

      if @options[:ignore_table_comment]
        from.delete(:comment)
        to.delete(:comment)
      end

      if Ridgepole::ConnectionAdapters.mysql?
        if @options[:mysql_change_table_options]
          from_options = from[:options] || {}
          to_options = to[:options] || {}

          if from_options != to_options
            table_delta[:table_options] = to_options
            from.delete(:options)
            to.delete(:options)
          end

          if from[:charset] != to[:charset]
            table_delta[:table_charset] = to[:charset]
            from.delete(:charset)
            to.delete(:charset)
          end

          if from[:collation] != to[:collation]
            table_delta[:table_collation] = to[:collation]
            from.delete(:collation)
            to.delete(:collation)
          end
        end

        if @options[:mysql_change_table_comment] && (from[:comment] != to[:comment])
          from.delete(:comment)
          to_comment = to.delete(:comment)
          table_delta[:table_comment] = to_comment
        end
      end

      if @options[:dump_without_table_options]
        from.delete(:options)
        from.delete(:charset)
        from.delete(:collation)
        to.delete(:options)
        to.delete(:charset)
        to.delete(:collation)
      end

      pk_attrs = build_primary_key_attrs_if_changed(from, to)
      if pk_attrs
        if @options[:allow_pk_change]
          if from[:id] == false
            delta_type = :add
            pk_attrs[:options][:primary_key] = true
          else
            delta_type = pk_attrs[:options][:id] == false ? :delete : :change
          end

          table_delta[:primary_key_definition] = { delta_type => { id: pk_attrs } }
        else
          @logger.warn(<<-MSG)
[WARNING] Primary key definition of `#{table_name}` differ but `allow_pk_change` option is false
  from: #{from.slice(*PRIMARY_KEY_OPTIONS)}
    to: #{to.slice(*PRIMARY_KEY_OPTIONS)}
        MSG
        end
      end
      from = from.except(*PRIMARY_KEY_OPTIONS)
      to = to.except(*PRIMARY_KEY_OPTIONS)

      unless from == to
        @logger.verbose_info(<<-MSG)
# Table option changes are ignored on `#{table_name}`.
  from: #{from}
    to: #{to}
      MSG
      end
    end

    def convert_to_primary_key_attrs(column_options)
      type = Ridgepole::DSLParser::TableDefinition::DEFAULT_PRIMARY_KEY_TYPE
      options = column_options.deep_dup

      if options[:id].is_a?(Hash)
        options_id = options.delete(:id)
        type = options_id.delete(:type) if options_id[:type]
        options.merge!(options_id.slice(*PRIMARY_KEY_OPTIONS))
      elsif options[:id]
        type = options.delete(:id)
      end

      options[:auto_increment] = true if %i[integer bigint].include?(type) && !options.key?(:default) && !Ridgepole::ConnectionAdapters.postgresql?

      { type: type, options: options }
    end

    def build_attrs_if_changed(to_attrs, from_attrs, primary_key: false)
      normalize_column_options!(from_attrs, primary_key)
      normalize_column_options!(to_attrs, primary_key)

      new_to_attrs = fix_change_column_options(from_attrs, to_attrs) unless compare_column_attrs(from_attrs, to_attrs)
      new_to_attrs
    end

    def build_primary_key_attrs_if_changed(from, to)
      from_column_attrs = convert_to_primary_key_attrs(from.slice(*PRIMARY_KEY_OPTIONS))
      to_column_attrs = convert_to_primary_key_attrs(to.slice(*PRIMARY_KEY_OPTIONS))
      return if from_column_attrs == to_column_attrs

      build_attrs_if_changed(to_column_attrs, from_column_attrs, primary_key: true)
    end

    def scan_definition_change(from, to, from_indices, table_name, table_options, table_delta)
      from = (from || {}).dup
      to = (to || {}).dup
      definition_delta = {}

      scan_column_rename(from, to, definition_delta)

      priv_column_name = if (table_options[:id] == false) || table_options[:primary_key].is_a?(Array)
                           nil
                         else
                           table_options[:primary_key] || 'id'
                         end

      to.each do |column_name, to_attrs|
        ignore_column = to_attrs.fetch(:options, {}).delete(:ignore)
        from_attrs = from.delete(column_name)
        next if ignore_column

        if from_attrs
          to_attrs = build_attrs_if_changed(to_attrs, from_attrs)
          if to_attrs
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

      if Ridgepole::ConnectionAdapters.postgresql?
        added_size = 0
        to.reverse_each.with_index do |(column_name, to_attrs), i|
          if to_attrs[:options].delete(:after)
            @logger.warn("[WARNING] PostgreSQL doesn't support adding a new column except for the last position. #{table_name}.#{column_name} will be added to the last.") if added_size != i
            added_size += 1
          end
        end
      end

      unless @options[:merge]
        from.each do |column_name, from_attrs|
          definition_delta[:delete] ||= {}
          definition_delta[:delete][column_name] = from_attrs

          next unless from_indices

          modified_indices = []

          from_indices.each do |name, attrs|
            modified_indices << name if attrs[:column_name].is_a?(Array) && attrs[:column_name].delete(column_name)
          end

          # In PostgreSQL, the index is deleted when the column is deleted
          if @options[:index_removed_drop_column]
            from_indices.reject! do |name, _attrs|
              modified_indices.include?(name)
            end
          end

          from_indices.reject! do |_name, attrs|
            attrs[:column_name].is_a?(Array) && attrs[:column_name].empty?
          end
        end
      end

      table_delta[:definition] = definition_delta unless definition_delta.empty?
    end

    def scan_column_rename(from, to, definition_delta)
      to.dup.each do |column_name, to_attrs|
        next unless (from_column_name = (to_attrs[:options] || {}).delete(:renamed_from))

        from_column_name = from_column_name.to_s if from_column_name

        # Already renamed
        next if from[column_name]

        raise "Column `#{from_column_name}` not found" unless from.key?(from_column_name)

        definition_delta[:rename] ||= {}
        definition_delta[:rename][column_name] = from_column_name

        from.delete(from_column_name)
        to.delete(column_name)
      end
    end

    def scan_indices_change(from, to, to_columns, table_delta, _from_table_options, to_table_options)
      from = (from || {}).dup
      to = (to || {}).dup
      indices_delta = {}

      to.each do |index_name, to_attrs|
        ignore_index = to_attrs.fetch(:options, {}).delete(:ignore)

        if index_name.is_a?(Array)
          from_index_name, from_attrs = from.find { |_name, attrs| attrs[:column_name] == index_name }

          if from_attrs
            from.delete(from_index_name)
            from_attrs[:options].delete(:name)
          end
        else
          from_attrs = from.delete(index_name)
        end

        next if ignore_index

        if from_attrs
          normalize_index_options!(from_attrs[:options])
          normalize_index_options!(to_attrs[:options])

          if from_attrs != to_attrs
            indices_delta[:add] ||= {}
            indices_delta[:add][index_name] = to_attrs

            unless @options[:merge]
              if columns_all_include?(from_attrs[:column_name], to_columns.keys, to_table_options)
                indices_delta[:delete] ||= {}
                indices_delta[:delete][index_name] = from_attrs
              end
            end
          end
        else
          indices_delta[:add] ||= {}
          indices_delta[:add][index_name] = to_attrs
        end
      end

      unless @options[:merge]
        from.each do |index_name, from_attrs|
          if columns_all_include?(from_attrs[:column_name], to_columns.keys, to_table_options)
            indices_delta[:delete] ||= {}
            indices_delta[:delete][index_name] = from_attrs
          end
        end
      end

      table_delta[:indices] = indices_delta unless indices_delta.empty?
    end

    def target?(table_name)
      if @options[:tables]&.include?(table_name)
        true
      elsif @options[:ignore_tables]&.any? { |i| i =~ table_name }
        false
      elsif @options[:tables]
        false
      else
        true
      end
    end

    def normalize_column_options!(attrs, primary_key = false)
      opts = attrs[:options]
      opts[:null] = true if !opts.key?(:null) && !primary_key
      default_limit = Ridgepole::DefaultsLimit.default_limit(attrs[:type], @options)
      opts.delete(:limit) if opts[:limit] == default_limit

      # XXX: MySQL only?
      opts[:default] = nil if !opts.key?(:default) && !primary_key

      if Ridgepole::ConnectionAdapters.mysql?
        opts[:unsigned] = false unless opts.key?(:unsigned)

        if attrs[:type] == :integer && opts[:limit]
          min = Ridgepole::DefaultsLimit.default_limit(:integer, @options)
          max = Ridgepole::DefaultsLimit.default_limit(:bigint, @options)
          if min < opts[:limit] && opts[:limit] <= max
            attrs[:type] = :bigint
            opts.delete(:limit)
          end
        end

        if opts[:size] && (attrs[:type] == :text || attrs[:type] == :blob || attrs[:type] == :binary)
          case opts.delete(:size)
          when :tiny
            attrs[:type] = :blob if attrs[:type] == :binary
            opts[:limit] = 255
          when :medium
            opts[:limit] = 16_777_215
          when :long
            opts[:limit] = 4_294_967_295
          end
        end
      end
    end

    def normalize_index_options!(opts)
      # XXX: MySQL only?
      opts[:using] = :btree unless opts.key?(:using)
      opts[:unique] = false unless opts.key?(:unique)
    end

    def columns_all_include?(expected_columns, actual_columns, table_options)
      return true unless expected_columns.is_a?(Array)

      actual_columns += [(table_options[:primary_key] || 'id').to_s] if (table_options[:id] != false) && !table_options[:primary_key].is_a?(Array)

      expected_columns.all? { |i| actual_columns.include?(i) }
    end

    def scan_foreign_keys_change(from, to, table_delta, options)
      from = (from || {}).dup
      to = (to || {}).dup
      foreign_keys_delta = {}

      to.each do |foreign_key_name_or_tables, to_attrs|
        ignore_fk = to_attrs.fetch(:options, {}).delete(:ignore)
        from_attrs = from.delete(foreign_key_name_or_tables)
        next if ignore_fk

        if from_attrs
          if from_attrs != to_attrs
            foreign_keys_delta[:add] ||= {}
            foreign_keys_delta[:add][foreign_key_name_or_tables] = to_attrs

            unless options[:merge]
              foreign_keys_delta[:delete] ||= {}
              foreign_keys_delta[:delete][foreign_key_name_or_tables] = from_attrs
            end
          end
        else
          foreign_keys_delta[:add] ||= {}
          foreign_keys_delta[:add][foreign_key_name_or_tables] = to_attrs
        end
      end

      unless options[:merge]
        from.each do |foreign_key_name_or_tables, from_attrs|
          foreign_keys_delta[:delete] ||= {}
          foreign_keys_delta[:delete][foreign_key_name_or_tables] = from_attrs
        end
      end

      table_delta[:foreign_keys] = foreign_keys_delta unless foreign_keys_delta.empty?
    end

    def scan_check_constraints_change(from, to, table_delta)
      from = (from || {}).dup
      to = (to || {}).dup
      check_constraints_delta = {}

      to.each do |name, to_attrs|
        from_attrs = from.delete(name)

        if from_attrs
          if from_attrs != to_attrs
            check_constraints_delta[:add] ||= {}
            check_constraints_delta[:add][name] = to_attrs

            check_constraints_delta[:delete] ||= {}
            check_constraints_delta[:delete][name] = from_attrs
          end
        else
          check_constraints_delta[:add] ||= {}
          check_constraints_delta[:add][name] = to_attrs
        end
      end

      unless @options[:merge]
        from.each do |name, from_attrs|
          check_constraints_delta[:delete] ||= {}
          check_constraints_delta[:delete][name] = from_attrs
        end
      end

      table_delta[:check_constraints] = check_constraints_delta unless check_constraints_delta.empty?
    end

    def scan_exclusion_constraints_change(from, to, table_delta)
      from = (from || {}).dup
      to = (to || {}).dup
      exclusion_constraints_delta = {}

      to.each do |name, to_attrs|
        from_attrs = from.delete(name)

        if from_attrs
          if from_attrs != to_attrs
            exclusion_constraints_delta[:add] ||= {}
            exclusion_constraints_delta[:add][name] = to_attrs

            exclusion_constraints_delta[:delete] ||= {}
            exclusion_constraints_delta[:delete][name] = from_attrs
          end
        else
          exclusion_constraints_delta[:add] ||= {}
          exclusion_constraints_delta[:add][name] = to_attrs
        end
      end

      unless @options[:merge]
        from.each do |name, from_attrs|
          exclusion_constraints_delta[:delete] ||= {}
          exclusion_constraints_delta[:delete][name] = from_attrs
        end
      end

      table_delta[:exclusion_constraints] = exclusion_constraints_delta unless exclusion_constraints_delta.empty?
    end

    def scan_unique_constraints_change(from, to, table_delta)
      from = (from || {}).dup
      to = (to || {}).dup
      unique_constraints_delta = {}

      to.each do |name, to_attrs|
        from_attrs = from.delete(name)

        if from_attrs
          if from_attrs != to_attrs
            unique_constraints_delta[:add] ||= {}
            unique_constraints_delta[:add][name] = to_attrs

            unique_constraints_delta[:delete] ||= {}
            unique_constraints_delta[:delete][name] = from_attrs
          end
        else
          unique_constraints_delta[:add] ||= {}
          unique_constraints_delta[:add][name] = to_attrs
        end
      end

      unless @options[:merge]
        from.each do |name, from_attrs|
          unique_constraints_delta[:delete] ||= {}
          unique_constraints_delta[:delete][name] = from_attrs
        end
      end

      table_delta[:unique_constraints] = unique_constraints_delta unless unique_constraints_delta.empty?
    end

    # XXX: MySQL only?
    # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/abstract_mysql_adapter.rb#L760
    # https://github.com/rails/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/abstract/schema_creation.rb#L102
    def fix_change_column_options(from_attrs, to_attrs)
      # default: 0, null: false -> default: nil, null: false | default: nil
      # default: 0, null: false ->               null: false | default: nil
      # default: 0, null: false -> default: nil, null: true  | default: nil, null: true
      # default: 0, null: false ->               null: true  | default: nil, null: true
      # default: 0, null: true  -> default: nil, null: true  | default: nil
      # default: 0, null: true  ->               null: true  | default: nil
      # default: 0, null: true  -> default: nil, null: false | default: nil, null: false (`default: nil` is ignored)
      # default: 0, null: true ->                null: false | default: nil, null: false (`default: nil` is ignored)

      if (from_attrs[:options][:default] != to_attrs[:options][:default]) && (from_attrs[:options][:null] == to_attrs[:options][:null])
        to_attrs = to_attrs.deep_dup
        to_attrs[:options].delete(:null)
      end

      to_attrs
    end

    def compare_column_attrs(attrs1, attrs2)
      attrs1 = attrs1.merge(options: attrs1.fetch(:options, {}).dup)
      attrs2 = attrs2.merge(options: attrs2.fetch(:options, {}).dup)
      normalize_default_proc_options!(attrs1[:options], attrs2[:options])

      if @options[:skip_column_comment_change]
        attrs1.fetch(:options).delete(:comment)
        attrs2.fetch(:options).delete(:comment)
      end

      if attrs1[:options][:as] != attrs2[:options][:as] && attrs1[:options].fetch(:as, '').delete(' ') == attrs2[:options].fetch(:as, '').delete(' ')
        @logger.warn(<<-MSG)
[WARNING] Same expressions but only differed by white spaces were detected. This operation may fail.
  Before: '#{attrs1[:options][:as]}'
  After : '#{attrs2[:options][:as]}'
        MSG
      end

      attrs1 == attrs2
    end

    def normalize_default_proc_options!(opts1, opts2)
      if opts1[:default].is_a?(Proc) && opts2[:default].is_a?(Proc)
        opts1[:default] = opts1[:default].call
        opts2[:default] = opts2[:default].call
      end
    end

    def diff_inspect(obj1, obj2, _options = {})
      obj1 = Ridgepole::Ext::PpSortHash.extend_if_hash(obj1)
      obj2 = Ridgepole::Ext::PpSortHash.extend_if_hash(obj2)

      diffy = Diffy::Diff.new(
        obj1.pretty_inspect,
        obj2.pretty_inspect,
        diff: '-u'
      )

      diffy.to_s(@options[:color] ? :color : :text).gsub(/\s+\z/m, '')
    end

    def collect_relation_info!(table_name, table_attr, relation_info)
      return unless @options[:check_relation_type]

      attrs_by_column = {}
      definition = table_attr[:definition] || {}

      definition.each do |column_name, column_attrs|
        attrs_by_column[column_name] = column_attrs.dup if column_name =~ /\w+_id\z/
      end

      relation_info[table_name] = {
        options: table_attr[:options] || {},
        columns: attrs_by_column,
      }
    end

    def scan_relation_info(relation_info)
      return unless @options[:check_relation_type]

      relation_info.each do |child_table, table_info|
        next unless target?(child_table)

        attrs_by_column = table_info.fetch(:columns)
        parent_table_info = nil

        attrs_by_column.each do |column_name, column_attrs|
          parent_table = column_name.sub(/_id\z/, '')

          [parent_table.pluralize, parent_table.singularize].each do |table_name|
            parent_table_info = relation_info[table_name]

            if parent_table_info
              parent_table = table_name
              break
            end
          end

          next unless parent_table_info

          table_options = parent_table_info.fetch(:options)
          next if table_options[:id] == false

          options_id = table_options[:id]
          parent_type, parent_unsigned = if options_id.is_a?(Hash)
                                           [options_id[:type], options_id[:unsigned]]
                                         else
                                           [table_options[:id], table_options[:unsigned]]
                                         end
          parent_column_info = {
            type: parent_type || @options[:check_relation_type].to_sym,
            unsigned: parent_unsigned,
          }

          child_column_info = {
            type: column_attrs[:type],
            unsigned: column_attrs.fetch(:options, {})[:unsigned],
          }

          [parent_column_info, child_column_info].each do |column_info|
            column_info.delete(:unsigned) unless column_info[:unsigned]

            # for PostgreSQL
            column_info[:type] = {
              serial: :integer,
              bigserial: :bigint,
            }.fetch(column_info[:type], column_info[:type])
          end

          next unless parent_column_info != child_column_info

          parent_label = "#{parent_table}.id"
          child_label = "#{child_table}.#{column_name}"
          label_len = [parent_label.length, child_label.length].max

          @logger.warn(format(<<-MSG, parent_label: parent_label, child_label: child_label))
[WARNING] Relation column type is different.
  %<parent_label>#{label_len}s: #{parent_column_info}
  %<child_label>#{label_len}s: #{child_column_info}
        MSG
        end
      end
    end

    def check_table_existence(definition)
      return unless @options[:tables]

      @options[:tables].each do |table_name|
        @logger.warn "[WARNING] '#{table_name}' definition is not found" unless definition.key?(table_name)
      end
    end
  end
end
