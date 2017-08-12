describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop column' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employees", id: :unsigned_integer, force: :cascade do |t|
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employees", id: :bigint, unsigned: true, force: :cascade do |t|
        end

        create_table "salaries", force: :cascade do |t|
          t.bigint "employee_id", null: false, unsigned: true
          t.index ["employee_id"], name: "fk_salaries_employees", <%= i cond(5.0, using: :btree) %>
        end
        add_foreign_key "salaries", "employees", name: "fk_salaries_employees"
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
