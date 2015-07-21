unless postgresql?
if migration_comments_enabled?
if mysql_awesome_enabled?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (add comment)' do
    let(:dsl) {
      <<-RUBY
        create_table "employee_clubs", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='テーブルコメント'" do |t|
          t.integer "emp_no",  limit: 4,     null: false, unsigned: true
          t.integer "club_id", limit: 4,     null: false
          t.string  "string",  limit: 255,   null: false,                 collation: "utf8mb4_bin"  # カラムコメント
          t.text    "text",    limit: 65535, null: false
        end
      RUBY
    }

    before do
      subject.diff('').migrate

      ActiveRecord::Base.connection.raw_connection.query(<<-EOS)
        CREATE TABLE `employee_clubs` (
          `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `emp_no` int(11) unsigned NOT NULL ,
          `club_id` int(11) NOT NULL ,
          `string` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'カラムコメント',
          `text` text NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='テーブルコメント';
      EOS
    end

    subject do
      client(enable_migration_comments: true, dump_without_table_options: false)
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq dsl.strip_heredoc.strip
    }
  end
end
end
end
end
