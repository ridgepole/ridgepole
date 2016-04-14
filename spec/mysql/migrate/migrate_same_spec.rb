describe 'Ridgepole::Client#diff -> migrate' do
  let(:template_variables) {
    opts = {
      unsigned: {},
      string_id: {},
      int_id: {},
    }

    if condition(:mysql_awesome_enabled)
      opts[:unsigned] = {unsigned: true}
      opts[:string_id] = {id: :string, limit: 4}
      opts[:int_id] = {id: :integer, limit: 4}
    end

    opts
  }

  context 'when database and definition are same' do
    let(:dsl) {
      erbh(<<-EOS, template_variables)
        create_table "clubs", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", <%= {force: :cascade}.unshift(@string_id).i %> do |t|
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

        create_table "employee_clubs", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.integer "emp_no",  <%= {limit: 4, null: false}.push(@unsigned).i %>
          t.integer "club_id", <%= {limit: 4, null: false}.push(@unsigned).i %>
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@int_id).i %> do |t|
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

    before { restore_tables }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy dsl
    }
  end
end
