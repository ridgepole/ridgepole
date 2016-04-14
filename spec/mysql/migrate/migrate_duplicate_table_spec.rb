describe 'Ridgepole::Client#diff -> migrate' do
  context 'when table already defined' do
    let(:dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date    "birth_date",                            null: false
          t.string  "first_name", limit: 14,                 null: false
          t.string  "last_name",  limit: 16,                 null: false
          t.string  "gender",     limit: 1,                  null: false
          t.date    "hire_date",                             null: false
          t.integer "age",                   unsigned: true, null: false
          t.date    "updated_at"
        end

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date    "birth_date",                            null: false
          t.string  "first_name", limit: 14,                 null: false
          t.string  "last_name",  limit: 16,                 null: false
          t.string  "gender",     limit: 1,                  null: false
          t.date    "hire_date",                             null: false
          t.integer "age",                   unsigned: true, null: false
          t.date    "updated_at"
        end
      EOS
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Table `employees` already defined')
    }
  end
end
