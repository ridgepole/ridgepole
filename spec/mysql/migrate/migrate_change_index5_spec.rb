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

  context 'when change index (unique: false)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "salaries", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "salary",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "salaries", ["emp_no", "id"], name: "emp_no", using: :btree
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "salaries", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "salary",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "salaries", ["emp_no", "id"], name: "emp_no", unique: false, using: :btree
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsy
    }
  end

  context 'when change index (unique: true)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "salaries", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "salary",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "salaries", ["emp_no", "id"], name: "emp_no", using: :btree
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "salaries", <%= {force: :cascade}.unshift(@unsigned).i %> do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "salary",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "salaries", ["emp_no", "id"], name: "emp_no", unique: true, using: :btree
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
