unless postgresql?
if mysql_awesome_enabled?
  describe 'Ridgepole::Client#dump' do
    let(:actual_dsl) {
      <<-'RUBY'
        create_table "books", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='\"london\" bridge \"is\" falling \"down\"'" do |t|
          t.string   "title",      limit: 255, null: false
          t.integer  "author_id",  limit: 4,   null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      RUBY
    }

    context 'when without table options' do
      let(:expected_dsl) {
        <<-RUBY
          create_table "books", unsigned: true, force: :cascade do |t|
            t.string   "title",      limit: 255, null: false
            t.integer  "author_id",  limit: 4,   null: false
            t.datetime "created_at"
            t.datetime "updated_at"
          end
        RUBY
      }

      before { subject.diff(actual_dsl).migrate }
      subject { client }

      it {
        expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
      }
    end

    context 'when with table options' do
      before { subject.diff(actual_dsl).migrate }
      subject { client(dump_without_table_options: false) }

      it {
        expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      }
    end
  end
end
end
