unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop column and index' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "clubs"#{unsigned_if_enabled}, force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no"#{unsigned_if_enabled}, force: :cascade do |t|
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

        create_table "employee_clubs"#{unsigned_if_enabled}, force: :cascade do |t|
          t.integer "emp_no",  limit: 4, null: false#{unsigned_if_enabled}
          t.integer "club_id", limit: 4, null: false#{unsigned_if_enabled}
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
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
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "clubs"#{unsigned_if_enabled}, force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string "dept_no", limit: 4, null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string "dept_no", limit: 4, null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree

        create_table "employee_clubs"#{unsigned_if_enabled}, force: :cascade do |t|
          t.integer "emp_no", limit: 4, null: false#{unsigned_if_enabled}
        end

        add_index "employee_clubs", ["emp_no"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
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
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate(:noop => true)
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
    }

    it {
      delta = client(:bulk_change => true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
change_table("dept_emp", {:bulk => true}) do |t|
  t.remove("emp_no")
  t.remove("from_date")
  t.remove("to_date")
end

change_table("dept_manager", {:bulk => true}) do |t|
  t.remove("emp_no")
  t.remove("from_date")
  t.remove("to_date")
end

change_table("employee_clubs", {:bulk => true}) do |t|
  t.remove("club_id")
end

change_table("employees", {:bulk => true}) do |t|
  t.remove("last_name")
  t.remove("gender")
  t.remove("hire_date")
end
      RUBY
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end
end
end
