# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table with ignore:true' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        create_table "dept_emp", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false, ignore: true
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no", <%= i cond(5.0, using: :btree) %>, ignore: true
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) { dsl.each_line.reject { |l| l =~ /ignore/ }.join }

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
end
