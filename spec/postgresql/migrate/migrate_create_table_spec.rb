describe 'Ridgepole::Client#diff -> migrate' do
  let(:template_variables) {
    opts = {
      dept_manager_pk: {primary_key: ["emp_no", "dept_no"]},
      dept_emp_pk: {primary_key: ["emp_no", "dept_no"]},
      salaries_pk: {primary_key: ["emp_no", "from_date"]},
      titles_pk: {primary_key: ["emp_no", "title", "from_date"]},
    }

    if condition(:activerecord_4)
      opts.merge!(
        dept_manager_pk: {id: false},
        dept_emp_pk: {id: false},
        salaries_pk: {id: false},
        titles_pk: {id: false}
      )
    end

    opts
  }

  context 'when create table' do
    let(:dsl) {
      erbh(<<-EOS, template_variables)
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        <%= add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree %>

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        create_table "dept_emp", <%= i @dept_emp_pk %>, force: :cascade do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "idx_dept_emp_dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "idx_dept_emp_emp_no", using: :btree %>

        create_table "dept_manager", <%= i @dept_manager_pk %>, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",              null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "idx_dept_manager_dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "idx_dept_manager_emp_no", using: :btree %>

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  null: false
          t.integer "club_id", null: false
        end

        <%= add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id", using: :btree %>

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", <%= i @salaries_pk %>, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "idx_salaries_emp_no", using: :btree %>

        create_table "titles", <%= i @titles_pk %>, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "idx_titles_emp_no", using: :btree %>
      EOS
    }

    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        create_table "dept_emp", <%= i @dept_emp_pk %>, force: :cascade do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "idx_dept_emp_dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "idx_dept_emp_emp_no", using: :btree %>

        create_table "dept_manager", <%= i @dept_manager_pk %>, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",              null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "idx_dept_manager_dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "idx_dept_manager_emp_no", using: :btree %>

        create_table "salaries", <%= i @salaries_pk %>, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "idx_salaries_emp_no", using: :btree %>

        create_table "titles", <%= i @titles_pk %>, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "idx_titles_emp_no", using: :btree %>
      EOS
    }

    let(:expected_dsl) { dsl }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        drop_table("clubs")

        drop_table("employee_clubs")

        drop_table("employees")
      EOS
    }
  end
end
