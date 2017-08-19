describe 'Ridgepole::Client#diff -> migrate' do
  context 'when use references (no change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.<%= cond(5.1, 'bigint', 'integer') %> "products_id"
          t.<%= cond(5.1, 'bigint', 'integer') %> "user_id"
          t.index "products_id"
          t.index "user_id"
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.references :products, :user, index: true
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
