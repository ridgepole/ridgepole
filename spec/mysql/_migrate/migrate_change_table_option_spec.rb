# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change mysql table options' do
    let(:actual_dsl) do
      erbh(<<-ERB, utf8: condition(:mysql80) ? 'utf8mb3' : 'utf8')
        create_table "employees", primary_key: "emp_no", force: :cascade, charset: "<%= @utf8 %>", options: "ENGINE=MyISAM"  do |t|
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
        create_table "employees", primary_key: "emp_no", force: :cascade, charset: "ascii"  do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false, collation: "utf8_general_ci"
          t.string "last_name", limit: 16, null: false, collation: "utf8_general_ci"
          t.string "gender", limit: 1, null: false, collation: "utf8_general_ci"
          t.date   "hire_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(dump_without_table_options: false, mysql_change_table_options: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump.gsub('utf8mb3_general_ci', 'utf8_general_ci')).to match_ruby expected_dsl
    }
  end
end
