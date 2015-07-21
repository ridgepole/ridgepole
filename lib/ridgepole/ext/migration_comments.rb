require 'migration_comments/active_record/schema_dumper'

module MigrationComments::ActiveRecord
  module SchemaDumper
    def append_comments(table, stream)
      table_name = table.inspect.gsub('"', '')
      column_comments = @connection.retrieve_column_comments(table_name)
      comment_stream = StringIO.new
      lines = []
      col_names = {}

      while (line = stream.gets)
        content = line.chomp

        if content =~ /t\.\w+\s+"(\w+)"/
          col_names[lines.size] = $1.to_sym
        end

        lines << content
      end

      len = col_names.keys.map{|index| lines[index]}.map(&:length).max + 2 unless col_names.empty?

      lines.each_with_index do |line, index|
        if col_names[index]
          comment = column_comments[col_names[index]]
          line << ' ' * (len - line.length) << "# #{comment}" unless comment.blank?
        end

        comment_stream.puts line
      end

      comment_stream.rewind
      comment_stream
    end
  end
end
