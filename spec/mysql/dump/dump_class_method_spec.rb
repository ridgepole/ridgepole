describe 'Ridgepole::Client.dump' do
  context 'when there is a tables' do
    before { restore_tables }
    subject { Ridgepole::Client }

    let(:options) {
      opts = {}

      if condition(:mysql_awesome_enabled)
        opts[:enable_mysql_awesome] = true
        opts[:dump_without_table_options] = true
      else
        opts[:enable_mysql_unsigned] = true
      end

      opts
    }

    let(:template_variables) {
      opts = {
        clubs: {force: :cascade},
        departments: {force: :cascade},
        employee_clubs: {force: :cascade},
        employees: {force: :cascade},
        unsigned: {},
      }

      if condition(:mysql_awesome_enabled)
        opts[:clubs].unshift(unsigned: true)
        opts[:departments].unshift(id: :string, limit: 4)
        opts[:employee_clubs].unshift(unsigned: true)
        opts[:employees].unshift(id: :integer, limit: 4)
        opts[:unsigned] = {unsigned: true}
      end

      opts
    }

    it {
      expect(subject.dump(conn_spec, options)).to match_fuzzy erbh(<<-EOS, template_variables)
        create_table "clubs", <%= @clubs.i %> do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", <%= @departments.i %> do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", <%= @employee_clubs.i %> do |t|
          t.integer "emp_no",  <%= {limit: 4, null: false}.push(@unsigned).i %>
          t.integer "club_id", <%= {limit: 4, null: false}.push(@unsigned).i %>
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", <%= @employees.i %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "salary",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      EOS
    }
  end
end
