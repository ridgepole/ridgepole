describe 'Ridgepole::Client (with pkdump)' do
  let(:dsl) {
    <<-RUBY
      create_table "authors", id: "bigint(20) PRIMARY KEY auto_increment", force: true do |t|
        t.string   "name",       null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "books", id: "bigint(20) PRIMARY KEY auto_increment", force: true do |t|
        t.string   "title",      null: false
        t.integer  "author_id",  null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    RUBY
  }

  context 'when dump with activerecord-mysql-pkdump' do
    subject { client(enable_mysql_pkdump: true) }

    before { subject.diff(dsl).migrate }

    it {
      expect(subject.dump).to eq dsl.strip_heredoc.strip
    }
  end

  context 'when create with activerecord-mysql-pkdump' do
    subject { client(enable_mysql_pkdump: true) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq ''
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'update create with activerecord-mysql-pkdump' do
    subject { client(enable_mysql_pkdump: true) }

    before { subject.diff(dsl).migrate }

    let(:dsl2) {
      <<-RUBY
        create_table "books", id: "bigint(20) PRIMARY KEY auto_increment", force: true do |t|
          t.string   "title2",     null: false
          t.integer  "author_id",  null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      RUBY
    }

    it {
      delta = subject.diff(dsl2)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq dsl2.strip_heredoc.strip.delete_empty_lines
    }
  end
end
