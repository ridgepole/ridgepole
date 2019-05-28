# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column ignore comment' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false, comment: "my comment"
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.index ["gender"], name: "gender", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table :employees, primary_key: :emp_no, force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false, comment: "my comment2"
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   :hire_date, null: false
          t.index :gender, name: :gender, <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(skip_column_comment_change: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
