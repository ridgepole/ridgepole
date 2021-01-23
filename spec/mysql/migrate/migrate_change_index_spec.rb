# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change index' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_emp_no_club_id"
        end

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
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "emp_no"
        end
      ERB
    end

    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_emp_no_club_id"
        end

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
          t.index ["emp_no"], name: "emp_no"
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "emp_no"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
          t.index ["dept_name"], name: "dept_name", unique: true
        end

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["from_date"], name: "emp_no"
        end

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["dept_no"], name: "dept_no"
          t.index ["from_date"], name: "emp_no"
        end

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false
          t.index ["emp_no", "club_id"], name: "idx_emp_no_club_id"
        end

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
          t.index ["from_date"], name: "emp_no"
        end

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
          t.index ["emp_no"], name: "emp_no"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        change_table("dept_emp", bulk: true) do |t|
          t.remove_index(name: "emp_no")
          t.index(["from_date"], **{:name=>"emp_no", :using=>:btree, :unique=>false})
        end

        change_table("dept_manager", bulk: true) do |t|
          t.remove_index(name: "emp_no")
          t.index(["from_date"], **{:name=>"emp_no", :using=>:btree, :unique=>false})
        end

        change_table("salaries", bulk: true) do |t|
          t.remove_index(name: "emp_no")
          t.index(["from_date"], **{:name=>"emp_no", :using=>:btree, :unique=>false})
        end
      RUBY
    }

    # duplicated index checker is deleted in 6.1
    # https://github.com/rails/rails/commit/edb23791d2ee9df89c5a4f24d72940ff8eaec8fc#diff-5a1c923abf3a794dbc133959167f794b2479ea8bcd0b1deda7766c22f05e8dfeL1198
    it 'detects duplicated index', condition: '< 6.1' do
      delta = client(bulk_change: true).diff(expected_dsl)

      # XXX: Can not add an index of the same name
      expect do
        delta.migrate
      end.to raise_error(/Index name 'emp_no' on table 'dept_emp' already exists/)
    end
  end
end
