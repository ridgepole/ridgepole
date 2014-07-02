describe 'Ridgepole::Client#diff -> migrate' do
  context 'when with ignore tables option (same)' do
    let(:current_schema) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    before { subject.diff(current_schema).migrate }
    subject { client(ignore_tables: [/^salaries$/] ) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_false
      expect(subject.dump).to eq expected_dsl.undent.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.undent.strip
    }
  end

  context 'when with ignore tables option (differ)' do
    let(:current_schema) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    }

    let(:before_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    let(:after_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    before { subject.diff(current_schema).migrate }
    subject { client(ignore_tables: [/^salaries$/] ) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_true
      expect(subject.dump).to eq before_dsl.undent.strip
      delta.migrate
      expect(subject.dump).to eq after_dsl.undent.strip
    }

    it {
      delta = Ridgepole::Client.diff(current_schema, dsl, ignore_tables: [/^salaries$/], reverse: true)
      expect(delta.differ?).to be_true
      expect(delta.script).to eq (<<-RUBY).undent.strip
        change_column("employees", "first_name", :string, {:limit=>14, :null=>false, :unsigned=>false})
      RUBY
    }
  end
end
