# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: :mysql80 do
  subject { client }

  context 'when add_index contains expression' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) { erbh(<<-ERB) }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.index "(lower(`name`))", name: "index_users_on_lower_name"
      end
    ERB

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end

  context 'when add_index contains expression that behaves like a partial index' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) { erbh(<<-ERB) }
      create_table "users", force: :cascade do |t|
        t.datetime "deleted_at"
        t.string "email", null: false
        t.index "(case when (`deleted_at` is null) then `email` else NULL end)", name: "index_users_on_active_email", unique: true
      end
    ERB

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end
end
