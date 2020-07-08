# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table' do
    let(:expected_dsl) do
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree
      RUBY
    end

    subject { client(table_options: 'ENGINE=MyISAM CHARSET=utf8') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      expect(delta.script).to match_fuzzy <<-RUBY
        create_table("employee_clubs", **{:options=>"ENGINE=MyISAM CHARSET=utf8"}) do |t|
          t.column("emp_no", :"integer", **{:null=>false, :unsigned=>true, :limit=>4})
          t.column("club_id", :"integer", **{:null=>false, :unsigned=>true, :limit=>4})
        end
        add_index("employee_clubs", ["emp_no", "club_id"], **{:name=>"idx_emp_no_club_id", :using=>:btree})
      RUBY
    }
  end

  context 'when create table (table definition options takes precedence)' do
    let(:expected_dsl) do
      <<-RUBY
        create_table "employee_clubs", force: :cascade, options: "ENGINE=InnoDB CHARSET=utf8mb4" do |t|
          t.integer "emp_no", null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree
      RUBY
    end

    subject { client(table_options: 'ENGINE=MyISAM CHARSET=utf8') }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      expect(delta.script).to match_fuzzy <<-RUBY
        create_table("employee_clubs", **{:options=>"ENGINE=InnoDB CHARSET=utf8mb4"}) do |t|
          t.column("emp_no", :"integer", **{:null=>false, :unsigned=>true, :limit=>4})
          t.column("club_id", :"integer", **{:null=>false, :unsigned=>true, :limit=>4})
        end
        add_index("employee_clubs", ["emp_no", "club_id"], **{:name=>"idx_emp_no_club_id", :using=>:btree})
      RUBY
    }
  end
end
