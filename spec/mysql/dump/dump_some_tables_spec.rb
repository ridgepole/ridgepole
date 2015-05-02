unless postgresql?
describe 'Ridgepole::Client#dump' do
  context 'when there is a tables (dump some tables)' do
    before { restore_tables }
    subject { client(tables: ['employees', 'salaries']) }

    it {
      expect(subject.dump).to eq <<-RUBY.strip_heredoc.strip
        create_table "employees", primary_key: "emp_no",#{if_mysql_awesome_enabled(' id: :integer, limit: 4,')} force: :cascade do |t|
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
      RUBY
    }
  end

  context 'when there is a tables (use ignore table)' do
    before { restore_tables }
    subject {
      client(ignore_tables: [
        /^clubs$/,
        /^departments$/,
        /^dept_emp$/,
        /^dept_manager$/,
        /^employee_clubs$/,
        /^titles$/,
      ])
    }

    it {
      expect(subject.dump).to eq <<-RUBY.strip_heredoc.strip
        create_table "employees", primary_key: "emp_no",#{if_mysql_awesome_enabled(' id: :integer, limit: 4,')} force: :cascade do |t|
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
      RUBY
    }
  end
end
end
