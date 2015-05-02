unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table' do
    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree
      RUBY
    }

    subject { client(table_options: 'ENGINE=MyISAM CHARSET=utf8') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        create_table("employee_clubs", {:options=>"ENGINE=MyISAM CHARSET=utf8"}) do |t|
          t.integer("emp_no", {:null=>false, :unsigned=>true, :limit=>4})
          t.integer("club_id", {:null=>false, :unsigned=>true, :limit=>4})
        end
        add_index("employee_clubs", ["emp_no", "club_id"], {:name=>"idx_emp_no_club_id", :using=>:btree})
      RUBY
    }
  end
end
end
