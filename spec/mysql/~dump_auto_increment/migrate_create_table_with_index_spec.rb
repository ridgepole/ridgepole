# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate (with index)' do
  context 'when create table with auto increment column' do
    let(:actual_dsl) { '' }

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "dept_no", null: false, auto_increment: true
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["emp_no"], name: "emp_no"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(create_table_with_index: true, mysql_dump_auto_increment: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      expect(delta.script).to match_fuzzy erbh(<<-ERB)
        create_table("dept_emp", **{:primary_key=>["emp_no", "dept_no"]}) do |t|
          t.column("emp_no", :"integer", **{:null=>false, :limit=>4})
          t.column("dept_no", :"integer", **{:null=>false, :auto_increment=>true, :limit=>4})
          t.column("from_date", :"date", **{:null=>false})
          t.column("to_date", :"date", **{:null=>false})
          t.index(["dept_no"], **{:name=>"dept_no"})
          t.index(["emp_no"], **{:name=>"emp_no"})
        end
      ERB

      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
