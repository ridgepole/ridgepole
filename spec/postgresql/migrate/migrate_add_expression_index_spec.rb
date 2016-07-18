describe 'Ridgepole::Client#diff -> migrate', condition: [:activerecord_5] do
  subject { client }

  context 'when add_index contains expression' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) { <<-EOS }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", using: :btree
      end
    EOS

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end
end
