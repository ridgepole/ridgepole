# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when delete index for foreign keys in dsl' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "departments", id: :bigint, force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        create_table "salaries", id: :bigint, force: :cascade do |t|
          t.integer "salary", null: false
        end

        create_table "employees", force: :cascade do |t|
          t.date   "birth_date", null: false, comment: "my comment"
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.bigint "department_id", null: false
          t.bigint "salary_id", null: false
          t.index ["department_id"]
          t.index ["salary_id"]
        end

        add_foreign_key "employees", "departments", name: "employees_fk_departments"
        add_foreign_key "employees", "salaries", name: "employees_fk_salaries"
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "departments", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        create_table "salaries", force: :cascade do |t|
          t.integer "salary", null: false
        end

        create_table "employees", force: :cascade do |t|
          t.date   "birth_date", null: false, comment: "my comment"
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.bigint "department_id", null: false
          t.bigint "salary_id", null: false
        end

        add_foreign_key "employees", "departments", name: "employees_fk_departments"
        add_foreign_key "employees", "salaries", name: "employees_fk_salaries"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(set_index_to_fk: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
