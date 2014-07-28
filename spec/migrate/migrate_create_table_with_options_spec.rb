describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table' do
    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  unsigned: true, null: false
          t.integer "club_id", unsigned: true, null: false
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree
      RUBY
    }

    subject { client(table_options: 'ENGINE=MyISAM CHARSET=utf8') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      puts delta.script
    }
  end
end
