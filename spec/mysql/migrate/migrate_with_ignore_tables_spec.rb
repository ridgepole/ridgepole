describe 'Ridgepole::Client#diff -> migrate' do
  context 'when with ignore tables option (same)' do
    let(:current_schema) {
      <<-EOS
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

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      EOS
    }

    let(:dsl) {
      <<-EOS
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
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(current_schema).migrate }
    subject { client(ignore_tables: [/^salaries$/] ) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy expected_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when with ignore tables option (differ)' do
    let(:current_schema) {
      <<-EOS
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

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      EOS
    }

    let(:dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
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
      EOS
    }

    let(:before_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    let(:after_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(current_schema).migrate }
    subject { client(ignore_tables: [/^salaries$/] ) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy before_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy after_dsl
    }

    it {
      delta = Ridgepole::Client.diff(current_schema, dsl, ignore_tables: [/^salaries$/], reverse: true, enable_mysql_awesome: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        change_column("employees", "first_name", :string, {:limit=>14, :null=>false, :default=>nil, :unsigned=>false})
      EOS
    }
  end

  context 'when with ignore tables option (target and ignore)' do
    let(:current_schema) {
      <<-EOS
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

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      EOS
    }

    let(:dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
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
      EOS
    }

    let(:before_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    let(:after_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(current_schema).migrate }
    subject { client(tables: ["employees"], ignore_tables: [/^.+$/] ) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy before_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy after_dsl
    }

    it {
      delta = Ridgepole::Client.diff(current_schema, dsl, ignore_tables: [/^salaries$/], reverse: true, enable_mysql_awesome: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        change_column("employees", "first_name", :string, {:limit=>14, :null=>false, :default=>nil, :unsigned=>false})
      EOS
    }
  end

  context 'when with ignore tables option (target)' do
    let(:current_schema) {
      <<-EOS
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

        add_index "salaries", ["salary"], name: "emp_no", using: :btree
      EOS
    }

    let(:dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
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
      EOS
    }

    let(:before_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    let(:after_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 15, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(current_schema).migrate }
    subject { client(tables: ["employees"]) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy before_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy after_dsl
    }

    it {
      delta = Ridgepole::Client.diff(current_schema, dsl, ignore_tables: [/^salaries$/], reverse: true, enable_mysql_awesome: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        change_column("employees", "first_name", :string, {:limit=>14, :null=>false, :default=>nil, :unsigned=>false})
      EOS
    }
  end
end
