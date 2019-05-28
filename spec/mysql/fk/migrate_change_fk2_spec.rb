# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "users", id: false, force: :cascade do |t|
          t.bigint :my_original_id, null: false
          t.index %i[my_original_id], unique: true
        end

        create_table "lessons", force: :cascade do |t|
          t.bigint :user_id2, null: false
          t.index %i[user_id2], name: :index_lessons_on_user_id2
        end

        add_foreign_key :lessons, :users, primary_key: :my_original_id, column: :user_id2
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "lessons", force: :cascade do |t|
          t.bigint "user_id2", null: false
          t.index ["user_id2"], name: "index_lessons_on_user_id2", <%= i cond(5.0, using: :btree) %>
        end

        create_table "users", id: false, force: :cascade do |t|
          t.bigint "my_original_id", null: false
          t.index ["my_original_id"], name: "index_users_on_my_original_id", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "lessons", "users", primary_key: "my_original_id", column: "user_id2"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      expect(subject.diff(actual_dsl).differ?).to be_falsey
      expect(subject.diff(expected_dsl).differ?).to be_falsey
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
