describe 'Ridgepole::Client#diff' do
  context 'when database is empty' do
    subject { client }

    it {
      delta = subject.diff(<<-RUBY)
        create_table "departments", primary_key: "dept_no", force: true do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: true do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: true do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",              null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      RUBY

      expect(delta.differ?).to be_true
      expect(delta.script).to be_same_str_as(<<-RUBY)
        create_table("departments", {:primary_key=>"dept_no"}) do |t|
          t.string("dept_name", {:limit=>40, :null=>false})
        end
        add_index("departments", ["dept_name"], {:name=>"dept_name", :unique=>true, :using=>:btree})

        create_table("dept_emp", {:id=>false}) do |t|
          t.integer("emp_no", {:null=>false})
          t.string("dept_no", {:limit=>4, :null=>false})
          t.date("from_date", {:null=>false})
          t.date("to_date", {:null=>false})
        end
        add_index("dept_emp", ["dept_no"], {:name=>"dept_no", :using=>:btree})
        add_index("dept_emp", ["emp_no"], {:name=>"emp_no", :using=>:btree})

        create_table("dept_manager", {:id=>false}) do |t|
          t.string("dept_no", {:limit=>4, :null=>false})
          t.integer("emp_no", {:null=>false})
          t.date("from_date", {:null=>false})
          t.date("to_date", {:null=>false})
        end
        add_index("dept_manager", ["dept_no"], {:name=>"dept_no", :using=>:btree})
        add_index("dept_manager", ["emp_no"], {:name=>"emp_no", :using=>:btree})

        create_table("employees", {:primary_key=>"emp_no"}) do |t|
          t.date("birth_date", {:null=>false})
          t.string("first_name", {:limit=>14, :null=>false})
          t.string("last_name", {:limit=>16, :null=>false})
          t.string("gender", {:limit=>1, :null=>false})
          t.date("hire_date", {:null=>false})
        end

        create_table("salaries", {:id=>false}) do |t|
          t.integer("emp_no", {:null=>false})
          t.integer("salary", {:null=>false})
          t.date("from_date", {:null=>false})
          t.date("to_date", {:null=>false})
        end
        add_index("salaries", ["emp_no"], {:name=>"emp_no", :using=>:btree})

        create_table("titles", {:id=>false}) do |t|
          t.integer("emp_no", {:null=>false})
          t.string("title", {:limit=>50, :null=>false})
          t.date("from_date", {:null=>false})
          t.date("to_date", {})
        end
        add_index("titles", ["emp_no"], {:name=>"emp_no", :using=>:btree})
      RUBY
    }
  end
end
