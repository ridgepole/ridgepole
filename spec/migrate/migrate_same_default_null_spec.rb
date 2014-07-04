describe 'Ridgepole::Client#diff -> migrate' do
  context 'when database and definition are same (default null / nothing -> null:true)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date"
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: true
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.undent.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.undent.strip.gsub(/\s*,\s*null: true/, '')
    }
  end

  context 'when database and definition are same (default null / null:true -> nothing)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: true
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date"
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.undent.strip.gsub(/\s*,\s*null: true/, '')
      delta.migrate
      expect(subject.dump).to eq expected_dsl.undent.strip
    }
  end
end
