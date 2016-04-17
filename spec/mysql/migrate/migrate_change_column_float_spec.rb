describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change float column' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",               null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(default_float_limit: 0) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy actual_dsl
    }
  end

  context 'when change float column (no change)' do
    let(:actual_dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.float   "salary",               null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
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
end
