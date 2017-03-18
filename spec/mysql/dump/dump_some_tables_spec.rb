describe 'Ridgepole::Client#dump' do
  context 'when there is a tables (dump some tables)' do
    before { restore_tables }
    subject { client(tables: ['employees', 'salaries']) }

    it {
      expect(subject.dump).to match_fuzzy erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", id: :integer, <%= i cond('5.1', default: nil) %>, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", primary_key: ["emp_no", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
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
      expect(subject.dump).to match_fuzzy erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", id: :integer, <%= i cond('5.1', default: nil) %>, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", primary_key: ["emp_no", "from_date"], force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
    }
  end
end
