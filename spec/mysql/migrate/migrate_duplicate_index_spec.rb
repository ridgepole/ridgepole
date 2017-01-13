describe 'Ridgepole::Client#diff -> migrate' do
  context 'when index already defined' do
    let(:dsl) {
      <<-EOS
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
      EOS
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Index `salaries(emp_no)` already defined')
    }
  end
end
