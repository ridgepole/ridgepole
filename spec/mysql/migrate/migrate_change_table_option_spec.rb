# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create_table options are different' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no2", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG)
[WARNING] Table option changes are ignored on `employees`.
  from: {:primary_key=>"emp_no"}
    to: {:primary_key=>"emp_no2"}
      MSG
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    }
  end

  context 'when create_table options are different (ignore comment)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", comment: "my comment", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(ignore_table_comment: true) }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    }
  end
end
