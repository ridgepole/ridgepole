describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column' do
    let(:dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Index `salaries(emp_no)` already defined')
    }
  end
end
