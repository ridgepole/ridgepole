describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (no change)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        <%= add_index "employees", ["gender"], name: "gender", using: :btree %>
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table :employees, primary_key: :emp_no, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   :hire_date,              null: false
        end

        <%= add_index :employees, :gender, name: :gender, using: :btree %>
      EOS
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
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        <%= add_index "employees", ["gender"], name: "gender", using: :btree %>
      EOS
    }

    let(:dsl) {
      erbh(<<-EOS)
        create_table :employees, primary_key: :emp_no, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   :hire_date2,             null: false
        end

        <%= add_index :employees, :last_name, name: :last_name, using: :btree %>
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date2",            null: false
        end

        <%= add_index "employees", ["last_name"], name: "last_name", using: :btree %>
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
