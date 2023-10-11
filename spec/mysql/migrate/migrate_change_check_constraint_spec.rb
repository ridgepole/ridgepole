# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: [[:mysql80]] do
  context 'when change check constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.check_constraint "`salary` > 100", name: "salary_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.check_constraint "`salary` > 200", name: "salary_check"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change check constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.check_constraint "`salary` > 100", name: "salary_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.check_constraint "`salary` > 200", name: "salary_check"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(marge: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
