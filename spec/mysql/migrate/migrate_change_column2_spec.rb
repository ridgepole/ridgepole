unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (no change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        add_index "employees", ["gender"], name: "gender", using: :btree
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table :employees, primary_key: :emp_no, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   :hire_date,              null: false
        end

        add_index :employees, :gender, name: :gender, using: :btree
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when change column (change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        add_index "employees", ["gender"], name: "gender", using: :btree
      RUBY
    }

    let(:dsl) {
      <<-RUBY
        create_table :employees, primary_key: :emp_no, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   :hire_date2,             null: false
        end

        add_index :employees, :last_name, name: :last_name, using: :btree
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date2",            null: false
        end

        add_index "employees", ["last_name"], name: "last_name", using: :btree
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
