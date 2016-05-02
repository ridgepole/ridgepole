describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change index (unique: false)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "salaries", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no", "id"], name: "emp_no", using: :btree %>
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "salaries", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no", "id"], name: "emp_no", unique: false, using: :btree %>
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
      erbh(<<-EOS)
        create_table "salaries", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no", "id"], name: "emp_no", using: :btree %>
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "salaries", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no", "id"], name: "emp_no", unique: true, using: :btree %>
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
