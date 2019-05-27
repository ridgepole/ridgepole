# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'integer/limit:8 = bigint' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", limit: 8, null: false
          t.float   "salary", <%= i cond('< 5.2.0.beta2', limit: 24) %>, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      expect(subject.dump).to match_ruby dsl.sub(/t.integer "emp_no", limit: 8/, 't.bigint "emp_no"')
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
