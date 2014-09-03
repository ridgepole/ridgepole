describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change index (same name)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no", "id"], name: "emp_no", using: :btree
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["salary", "id"], name: "emp_no", using: :hash
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:table_options => 'ENGINE=MEMORY') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'when change index (same name) (2)' do
    let(:actual_dsl) {
      <<-RUBY
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
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["salary"], name: "emp_no", using: :hash
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:table_options => 'ENGINE=MEMORY') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'when change index (same name) (2)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", primary_key: "emp_no", force: true do |t|
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["salary", "emp_no"], name: "emp_no", using: :btree
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", primary_key: "emp_no", force: true do |t|
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["from_date", "emp_no"], name: "emp_no", using: :hash
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:table_options => 'ENGINE=MEMORY') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end
end
