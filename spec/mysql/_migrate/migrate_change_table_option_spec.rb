# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change mysql table options' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
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
        create_table "employees", primary_key: "emp_no", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=ascii" do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false, <%= i cond('>= 5.2', collation: "utf8_general_ci") %>
          t.string "last_name", limit: 16, null: false, <%= i cond('>= 5.2', collation: "utf8_general_ci") %>
          t.string "gender", limit: 1, null: false, <%= i cond('>= 5.2', collation: "utf8_general_ci") %>
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
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
