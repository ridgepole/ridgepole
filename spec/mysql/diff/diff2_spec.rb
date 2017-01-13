describe 'Ridgepole::Client.diff' do
  context 'when change column' do
    let(:tmpdir) { Dir.mktmpdir }

    let(:actual_dsl) {
      open("#{tmpdir}/file1.required", 'w') do |f|
        f.puts <<-EOS
          create_table "clubs", force: :cascade do |t|
            t.string "name", default: "", null: false
          end

          add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

          create_table "departments", primary_key: "dept_no", force: :cascade do |t|
            t.string "dept_name", limit: 40, null: false
          end

          add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

          create_table "dept_emp", id: false, force: :cascade do |t|
            t.integer "emp_no",              null: false
            t.string  "dept_no",   limit: 4, null: false
            t.date    "from_date",           null: false
            t.date    "to_date",             null: false
          end

          add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
          add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

          create_table "dept_manager", id: false, force: :cascade do |t|
            t.string  "dept_no",   limit: 4, null: false
            t.integer "emp_no",              null: false
            t.date    "from_date",           null: false
            t.date    "to_date",             null: false
          end

          add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
          add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree
        EOS
      end

      f = open("#{tmpdir}/file1", 'w+')

      f.puts <<-EOS
        require "file1.required"

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      EOS

      f.flush
      f.rewind
      f
    }

    let(:expected_dsl) {
      open("#{tmpdir}/file2.required", 'w') do |f|
        f.puts <<-EOS
          create_table "clubs", force: :cascade do |t|
            t.string "name", default: "", null: false
          end

          add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

          create_table "departments", primary_key: "dept_no", force: :cascade do |t|
            t.string "dept_name", limit: 40, null: false
          end

          add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

          create_table "dept_emp", id: false, force: :cascade do |t|
            t.integer "emp_no",              null: false
            t.string  "dept_no",   limit: 4, null: false
            t.date    "from_date",           null: false
            t.date    "to_date",             null: false
          end

          add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
          add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

          create_table "dept_manager", id: false, force: :cascade do |t|
            t.string  "dept_no",   limit: 4, null: false
            t.integer "emp_no",              null: false
            t.date    "from_date",           null: false
            t.date    "to_date",             null: false
          end

          add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
          add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree
        EOS
      end

      f = open("#{tmpdir}/file2", 'w+')

      f.puts <<-EOS
        require "file2.required"

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  unsigned: true, null: false
          t.integer "club_id", unsigned: false, null: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",                            null: false
          t.string "first_name", limit: 14,                 null: false
          t.string "last_name",  limit: 20, default: "XXX", null: false
          t.string "gender",     limit: 2,                  null: false
          t.date   "hire_date",                             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      EOS

      f.flush
      f.rewind
      f
    }

    subject { Ridgepole::Client }

    it {
      delta = subject.diff(actual_dsl, expected_dsl, enable_mysql_unsigned: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        change_column("employee_clubs", "club_id", :integer, {:unsigned=>false, :null=>true, :default=>nil})

        change_column("employees", "last_name", :string, {:limit=>20, :default=>"XXX"})
        change_column("employees", "gender", :string, {:limit=>2, :null=>false, :default=>nil})
      EOS
    }

    after do
      FileUtils.remove_entry_secure(tmpdir)
    end
  end
end
