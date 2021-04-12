# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'integer/limit:8 = bigint' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no_int", limit: 4, null: false
          t.integer "emp_no_bigint5", limit: 5, null: false
          t.integer "emp_no_bigint6", limit: 6, null: false
          t.integer "emp_no_bigint7", limit: 7, null: false
          t.integer "emp_no_bigint8", limit: 8, null: false
          t.float   "salary", <%= i cond('< 5.2.0.beta2', limit: 24) %>, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      expect(subject.dump).to match_ruby dsl
        .sub(/t.integer "emp_no_int", limit: 4/, 't.integer "emp_no_int"')
        .sub(/t.integer "emp_no_bigint5", limit: 5/, 't.bigint "emp_no_bigint5"')
        .sub(/t.integer "emp_no_bigint6", limit: 6/, 't.bigint "emp_no_bigint6"')
        .sub(/t.integer "emp_no_bigint7", limit: 7/, 't.bigint "emp_no_bigint7"')
        .sub(/t.integer "emp_no_bigint8", limit: 8/, 't.bigint "emp_no_bigint8"')
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
