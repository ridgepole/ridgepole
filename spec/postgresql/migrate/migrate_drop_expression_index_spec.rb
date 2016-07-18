describe 'Ridgepole::Client#diff -> migrate', condition: [:activerecord_5] do
  subject { client }

  before do
    subject.diff(actual_dsl).migrate
  end

  context 'when drop column from table containing an expression index' do
    let(:actual_dsl) { <<-EOS }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.datetime "created_at", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", using: :btree
      end
    EOS

    let(:expected_dsl) { <<-EOS }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", using: :btree
      end
    EOS

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(delta.script).to match_fuzzy('remove_column("users", "created_at")')
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end

  context 'when drop expression index' do
    let(:actual_dsl) { <<-EOS }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", using: :btree
      end
    EOS

    let(:expected_dsl) { <<-EOS }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
      end
    EOS

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(delta.script).to match_fuzzy('remove_index("users", {:name=>"index_users_on_lower_name"})')
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end
end
