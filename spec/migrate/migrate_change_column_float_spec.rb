describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change float column' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",               null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
    }
  end

  context 'when change float column (no change)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",               null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(normalize_mysql_float: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end
end
