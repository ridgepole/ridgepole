describe 'Ridgepole::Client (with integer pk)', condition: '5.1.' do
  context 'when with id:integer' do
    let(:dsl) {
      <<-RUBY
        create_table "books", id: :integer, force: :cascade do |t|
          t.string   "title",      null: false
          t.integer  "author_id",  null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      RUBY
    }

    subject { client }

    before { subject.diff(dsl).migrate }

    specify {
      expect(show_create_table(:books)).to include '`id` int(11) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy dsl
    }
  end

  context 'when without id:integer' do
    let(:dsl) {
      <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string   "title",      null: false
          t.integer  "author_id",  null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      RUBY
    }

    subject { client }

    before { subject.diff(dsl).migrate }

    specify {
      expect(show_create_table(:books)).to include '`id` bigint(20) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy dsl
    }
  end
end
