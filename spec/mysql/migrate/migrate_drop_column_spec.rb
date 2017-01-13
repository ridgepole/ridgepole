describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop column' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "clubs", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.string "name", <%= i limit(255) + {default: "", null: false} %>
        end

        <%= add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree %>

        create_table "departments", primary_key: "dept_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.string "dept_name", limit: 40, null: false
        end

        <%= add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree %>

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "dept_no",   <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no",   <%= i limit(4) + {null: false} %>
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "employee_clubs", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} + unsigned(true) %>
          t.integer "club_id", <%= i limit(4) + {null: false} + unsigned(true) %>
        end

        <%= add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree %>

        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "emp_no", using: :btree %>
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "clubs", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.string "name", <%= i limit(255) + {default: "", null: false} %>
        end

        <%= add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree %>

        create_table "departments", primary_key: "dept_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.string "dept_name", limit: 40, null: false
        end

        <%= add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree %>

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.string  "dept_no", <%= i limit(4) + {null: false} %>
        end

        <%= add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", <%= i limit(4) + {null: false} %>
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
        end

        <%= add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree %>
        <%= add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "employee_clubs", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} + unsigned(true) %>
          t.integer "club_id", <%= i limit(4) + {null: false} + unsigned(true) %>
        end

        <%= add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree %>

        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.integer "salary",    <%= i limit(4) + {null: false} %>
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        <%= add_index "salaries", ["emp_no"], name: "emp_no", using: :btree %>

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        <%= add_index "titles", ["emp_no"], name: "emp_no", using: :btree %>
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

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        add_column("dept_emp", "from_date", :date, {:null=>false, :after=>"dept_no"})
        add_column("dept_emp", "to_date", :date, {:null=>false, :after=>"from_date"})

        add_column("dept_manager", "from_date", :date, {:null=>false, :after=>"emp_no"})
        add_column("dept_manager", "to_date", :date, {:null=>false, :after=>"from_date"})

        add_column("employees", "last_name", :string, {:limit=>16, :null=>false, :after=>"first_name"})
        add_column("employees", "gender", :string, {:limit=>1, :null=>false, :after=>"last_name"})
        add_column("employees", "hire_date", :date, {:null=>false, :after=>"gender"})
      EOS
    }

    it {
      delta = client(:bulk_change => true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        change_table("dept_emp", {:bulk => true}) do |t|
          t.remove("from_date")
          t.remove("to_date")
        end

        change_table("dept_manager", {:bulk => true}) do |t|
          t.remove("from_date")
          t.remove("to_date")
        end

        change_table("employees", {:bulk => true}) do |t|
          t.remove("last_name")
          t.remove("gender")
          t.remove("hire_date")
        end
      EOS
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
