unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when use timestamps (no change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.datetime "created_at",            null: false
          t.datetime "updated_at",            null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.timestamps
        end
      RUBY
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
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.timestamps
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.datetime "created_at",            null: false
          t.datetime "updated_at",            null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip.gsub(/(\s*,\s*unsigned: false)?\s*,\s*null: true/, '')
    }
  end

  context 'when use references (no change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date",            null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name",  limit: 16, null: false
          t.string   "gender",     limit: 1,  null: false
          t.date     "hire_date",             null: false
          t.integer "products_id"
          t.integer "user_id"
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.references :products, :user
        end
      RUBY
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
      <<-RUBY
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
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.references :products, :user, polymorphic: true
        end
      RUBY
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
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.references :products, :user
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date    "birth_date",             null: false
          t.string  "first_name",  limit: 14, null: false
          t.string  "last_name",   limit: 16, null: false
          t.string  "gender",      limit: 1,  null: false
          t.date    "hire_date",              null: false
          t.integer "products_id", limit: 4
          t.integer "user_id",     limit: 4
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip.gsub(/(\s*,\s*unsigned: false)?\s*,\s*null: true/, '')
    }
  end

  context 'when use references with polymorphic (change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
          t.references :products, :user, polymorphic: true
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
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
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip.gsub(/(\s*,\s*unsigned: false)?\s*,\s*null: true/, '')
    }
  end
end
end
