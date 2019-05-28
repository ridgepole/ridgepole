# frozen_string_literal: true

describe 'Ridgepole::Client (with bigint pk)', condition: 5.0 do
  let(:id_primary_key_create_table) do
    <<-RUBY
      create_table "books", id: :primary_key, limit: 8, force: :cascade do |t|
        t.string   "title", null: false
        t.integer  "author_id", null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    RUBY
  end

  let(:id_bigint_create_table) do
    <<-RUBY
      create_table "books", id: :bigint, force: :cascade do |t|
        t.string   "title", null: false
        t.integer  "author_id", null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    RUBY
  end

  context 'when with limit:8' do
    subject { client }

    before { subject.diff(id_primary_key_create_table).migrate }

    it {
      expect(show_create_table(:books)).to include '`id` bigint(20) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy id_bigint_create_table
    }
  end

  context 'when with id:bigint' do
    subject { client }

    before { subject.diff(id_bigint_create_table).migrate }

    it {
      expect(show_create_table(:books)).to include '`id` bigint(20) NOT NULL AUTO_INCREMENT'
      expect(subject.dump).to match_fuzzy id_bigint_create_table
    }
  end
end
