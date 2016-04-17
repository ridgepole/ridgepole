describe 'Ridgepole::Client#dump' do
  context 'when there is a tables' do
    before { restore_tables }
    subject { client }

    let(:template_variables) {
      opts = {
        departments_ext: {},
        employees_ext: {},
        unsigned: {},
        dept_manager_pk: {primary_key: ["emp_no", "dept_no"]},
        dept_emp_pk: {primary_key: ["emp_no", "dept_no"]},
        salaries_pk: {primary_key: ["emp_no", "from_date"]},
        titles_pk: {primary_key: ["emp_no", "title", "from_date"]},
      }

      if condition(:mysql_awesome_enabled, :activerecord_5)
        opts[:employees_ext].unshift(limit: 4) if condition(:mysql_awesome_enabled)
        opts[:employees_ext].unshift(id: :integer)

        opts.merge!(
          departments_ext: {id: :string, limit: 4},
          unsigned: {unsigned: true}
        )
      end

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

    it {
      expect(subject.dump).to match_fuzzy erbh(<<-EOS, template_variables)
        create_table "clubs", <%= i @unsigned + {force: :cascade} %> do |t|
          t.string "name", <%= i limit(255) + {default: "", null: false} %>
        end

        <%= add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree %>

        create_table "departments", primary_key: "dept_no", <%= i @departments_ext + {force: :cascade} %> do |t|
          t.string "dept_name", limit: 40, null: false
        end

        <%= add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree %>

        create_table "dept_emp", <%= i @dept_emp_pk %>, force: :cascade do |t|
          t.integer "emp_no", <%= i limit(4) + {null: false} %>
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "dept_manager", <%= i @dept_manager_pk %>, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no", <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "employee_clubs", <%= i @unsigned + {force: :cascade} %> do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} + @unsigned %>
          t.integer "club_id", <%= i limit(4) + {null: false} + @unsigned %>
        end

        <%= add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree %>

        create_table "employees", primary_key: "emp_no", <%= i @employees_ext + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", <%= i @salaries_pk %>, force: :cascade do |t|
          t.integer "emp_no", <%= i limit(4) + {null: false} %>
          t.integer "salary", <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "titles", <%= i @titles_pk %>, force: :cascade do |t|
          t.integer "emp_no", <%= i limit(4) + {null: false} %>
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
    }
  end
end
