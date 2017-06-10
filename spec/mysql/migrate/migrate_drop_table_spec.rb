describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop table' do
    let(:dsl) {
      erbh(<<-EOS)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
        end

        <%= add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree %>

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        <%= add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree %>

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
        end

        <%= add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree %>

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
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
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
    }

    let(:actual_dsl) { dsl }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        <%= add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree %>

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
    }

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
      expect(delta.script).to match_fuzzy erbh(<<-EOS)
        create_table("clubs", {}) do |t|
          t.column("name", :"string", {:default=>"", :null=>false, :limit=>255})
        end
        add_index("clubs", ["name"], <%= {:name=>"idx_name", :unique=>true} + cond(5.0, using: :btree) %>)

        create_table("employee_clubs", {}) do |t|
          t.column("emp_no", :"integer", {:null=>false, :limit=>4})
          t.column("club_id", :"integer", {:null=>false, :limit=>4})
        end
        add_index("employee_clubs", ["emp_no", "club_id"], <%= {:name=>"idx_emp_no_club_id"} + cond(5.0, using: :btree) %>)

        create_table("employees", {:primary_key=>"emp_no"}) do |t|
          t.column("birth_date", :"date", {:null=>false})
          t.column("first_name", :"string", {:limit=>14, :null=>false})
          t.column("last_name", :"string", {:limit=>16, :null=>false})
          t.column("gender", :"string", {:limit=>1, :null=>false})
          t.column("hire_date", :"date", {:null=>false})
        end
      EOS
    }
  end
end
