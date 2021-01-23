# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when database and definition are same' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", id: :serial, force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", <%= i cond(">= 6.1", { id: { type: :string, limit: 4 } }, { id: :string, limit: 4 }) %>, force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "idx_dept_name", unique: true
        end

        create_table "dept_emp", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_emp_dept_no"
          t.index ["emp_no"], name: "idx_dept_emp_emp_no"
        end

        create_table "dept_manager", primary_key: ["emp_no", "dept_no"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "idx_dept_manager_dept_no"
          t.index ["emp_no"], name: "idx_dept_manager_emp_no"
        end

        create_table "employee_clubs", id: :serial, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id"
        end

        create_table "employees", primary_key: "emp_no", id: :integer, default: nil, force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", primary_key: ["emp_no", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "idx_salaries_emp_no"
        end

        create_table "titles", primary_key: ["emp_no", "title", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "idx_titles_emp_no"
        end
      ERB
    end

    before { restore_tables }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby dsl
      delta.migrate
      expect(subject.dump).to match_ruby dsl
    }
  end
end
