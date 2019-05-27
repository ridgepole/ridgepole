# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when rename table' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no", <%= i cond(5.0, using: :btree) %>
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no", <%= i cond(5.0, using: :btree) %>
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_emp_no_club_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "employees2", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true, <%= i cond(5.0, using: :btree) %>
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no", <%= i cond(5.0, using: :btree) %>
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no", <%= i cond(5.0, using: :btree) %>
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_emp_no_club_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "employees2", primary_key: "emp_no", force: :cascade, renamed_from: 'employees' do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with('[WARNING] The table `employees` has already been renamed to the table `employees2`.')
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl.gsub(/, renamed_from: 'employees'/, '')
    }
  end
end
