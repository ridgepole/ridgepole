describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change index without using (no change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no"
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

  context 'when change index without using (change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    let(:dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["salary"], using: :hash
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["salary"], name: "index_salaries_on_salary", using: :hash
        end
      EOS
    }

    before { subject.diff(<<-EOS).migrate }
      create_table "salaries", id: false, force: :cascade do |t|
        t.integer "emp_no", null: false
        t.integer "salary", null: false
        t.date    "from_date", null: false
        t.date    "to_date", null: false
      end

      add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
    EOS

    subject { client(:table_options => 'ENGINE=MEMORY') }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change index without name (no change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], <%= i cond(5.0, using: :btree) %>
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

  context 'when change index without name (change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["emp_no"], name: "emp_no", <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    let(:dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["salary"], <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
          t.index ["salary"], name: "index_salaries_on_salary", <%= i cond(5.0, using: :btree) %>
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
