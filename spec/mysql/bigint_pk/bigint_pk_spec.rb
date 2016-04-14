describe 'Ridgepole::Client (with bigint pk)', condition: [:mysql_awesome_enabled] do
  let(:dsl1) {
    <<-RUBY
      create_table "books", id: :primary_key, limit: 8, force: :cascade do |t|
        t.string   "title",      limit: 255, null: false
        t.integer  "author_id",  limit: 4,   null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    RUBY
  }

  let(:dsl2) {
    <<-RUBY
      create_table "books", id: :bigint, force: :cascade do |t|
        t.string   "title",      limit: 255, null: false
        t.integer  "author_id",  limit: 4,   null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    RUBY
  }

  context 'when with limit:8' do
    subject { client }

    before { subject.diff(dsl1).migrate }

    it {
      expect(show_create_table(:books)).to include '`id` bigint(20) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy dsl2
    }
  end

  context 'when with id:bigint' do
    subject { client }

    before { subject.diff(dsl2).migrate }

    it {
      expect(show_create_table(:books)).to include '`id` bigint(20) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy dsl2
    }
  end
end
