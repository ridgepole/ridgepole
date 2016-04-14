describe 'Ridgepole::Client#diff -> migrate' do
  let(:template_variables) {
    opts = {
      unsigned: {}
    }

    if condition(:mysql_awesome_enabled)
      opts[:unsigned] = {unsigned: true}
    end

    opts
  }

  context 'when use timestamps (no change)' do
    let(:actual_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.datetime "created_at",            null: false
          t.datetime "updated_at",            null: false
        end
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
          t.timestamps
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use timestamps (change)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
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
          t.timestamps
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.datetime "created_at",            null: false
          t.datetime "updated_at",            null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when use references (no change)' do
    let(:actual_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.integer "products_id"
          t.integer "user_id"
        end
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
          t.references :products, :user
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references with polymorphic (no change)' do
    let(:actual_dsl) {
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.integer  "products_id"
          t.string   "products_type"
          t.integer  "user_id"
          t.string   "user_type"
        end
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
          t.references :products, :user, polymorphic: true
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references (change)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
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
          t.references :products, :user
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date    "birth_date",             null: false
          t.string  "first_name",  limit: 14, null: false
          t.string  "last_name",   limit: 16, null: false
          t.string  "gender",      limit: 1,  null: false
          t.date    "hire_date",              null: false
          t.integer "products_id", limit: 4
          t.integer "user_id",     limit: 4
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when use references with polymorphic (change)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
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
          t.references :products, :user, polymorphic: true
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "employees", primary_key: "emp_no", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.date    "birth_date",                null: false
          t.string  "first_name",    limit: 14,  null: false
          t.string  "last_name",     limit: 16,  null: false
          t.string  "gender",        limit: 1,   null: false
          t.date    "hire_date",                 null: false
          t.integer "products_id",   limit: 4
          t.string  "products_type", limit: 255
          t.integer "user_id",       limit: 4
          t.string  "user_type",     limit: 255
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
