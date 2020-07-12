# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  subject { client }

  before do
    subject.diff(actual_dsl).migrate
  end

  context 'when drop column from table containing an expression index' do
    let(:actual_dsl) { erbh(<<-ERB) }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.datetime "created_at", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", <%= i cond(5.0, using: :btree) %>
      end
    ERB

    let(:expected_dsl) { erbh(<<-ERB) }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", <%= i cond(5.0, using: :btree) %>
      end
    ERB

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
    let(:actual_dsl) { erbh(<<-ERB) }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
        t.index "lower((name)::text)", name: "index_users_on_lower_name", <%= i cond(5.0, using: :btree) %>
      end
    ERB

    let(:expected_dsl) { <<-RUBY }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
      end
    RUBY

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta).to be_differ
      expect(delta.script).to match_fuzzy('remove_index("users", name: "index_users_on_lower_name")')
      expect(subject.dump).to match_fuzzy(actual_dsl)
      delta.migrate
      expect(subject.dump).to match_fuzzy(expected_dsl)
    end
  end
end
