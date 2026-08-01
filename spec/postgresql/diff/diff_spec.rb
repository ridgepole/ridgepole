# frozen_string_literal: true

describe 'Ridgepole::Client.diff' do
  before do
    allow(Ridgepole::Diff).to receive(:postgresql?).and_return(true)
  end

  context 'when change column' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "idx_dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_emp", ["dept_no"], name: "idx_dept_emp_dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "idx_dept_emp_emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_manager", ["dept_no"], name: "idx_dept_manager_dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "idx_dept_manager_emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "club_id", null: false
          t.integer "emp_no", null: false
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.date   "hire_date", null: false
          t.string "last_name", limit: 16, null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.integer "salary", null: false
          t.date    "to_date", null: false
        end

        add_index "salaries", ["emp_no"], name: "idx_salaries_emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.string  "title", limit: 50, null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "idx_titles_emp_no", using: :btree
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "idx_dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_emp", ["dept_no"], name: "idx_dept_emp_dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "idx_dept_emp_emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_manager", ["dept_no"], name: "idx_dept_manager_dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "idx_dept_manager_emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "club_id", null: true
          t.integer "emp_no", null: false
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_employee_clubs_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.date   "hire_date", null: false
          t.string "last_name", limit: 20, default: "XXX", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.integer "salary", null: false
          t.date    "to_date", null: false
        end

        add_index "salaries", ["emp_no"], name: "idx_salaries_emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.string  "title", limit: 50, null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "idx_titles_emp_no", using: :btree
      RUBY
    end

    subject { Ridgepole::Client }

    it {
      delta = subject.diff(actual_dsl, expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-RUBY
        change_column("employee_clubs", "club_id", :integer, **#{{ null: true, default: nil }})

        change_column("employees", "last_name", :string, **#{{ limit: 20, default: 'XXX' }})
      RUBY
    }
  end

  describe 'column position warning' do
    subject { Ridgepole::Client }

    context 'when adding a column to the last' do
      let(:actual_dsl) { <<-RUBY }
      create_table "users", force: :cascade do |t|
        t.datetime "created_at", null: false
      end
      RUBY

      let(:expected_dsl) { <<-RUBY }
      create_table "users", force: :cascade do |t|
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.string "name", null: false
      end
      RUBY

      # XXX:
      before { client }

      it "doesn't warn anything" do
        expect(Ridgepole::Logger.instance).to_not receive(:warn)
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to_not include('after')
      end
    end

    context 'when adding a column to the middle' do
      let(:actual_dsl) { <<-RUBY }
      create_table "users", force: :cascade do |t|
        t.string "name", null: false
      end
      RUBY

      let(:expected_dsl) { <<-RUBY }
      create_table "users", force: :cascade do |t|
        t.datetime "created_at", null: false
        t.integer "age", null: false
        t.string "name", null: false
        t.datetime "updated_at", null: false
      end
      RUBY

      # XXX:
      before { client }

      it 'warns position' do
        expect(Ridgepole::Logger.instance).to receive(:warn).with(/PostgreSQL doesn't support adding a new column .* users\.created_at/)
        expect(Ridgepole::Logger.instance).to receive(:warn).with(/PostgreSQL doesn't support adding a new column .* users\.age/)
        expect(Ridgepole::Logger.instance).to_not receive(:warn)
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to_not include('after')
      end
    end
  end

  context 'when applying foreign key with specific schema (issue #606)' do
    let(:actual_dsl) { <<-RUBY }
    create_table "users", force: :cascade do |t|
      t.string "name", null: false
    end
    create_table "entries", force: :cascade do |t|
      t.references :user, null: false, foreign_key: true
    end
    RUBY

    let(:expected_dsl) { <<-RUBY }
    create_table "users", force: :cascade do |t|
      t.string "name", null: false
    end
    create_table "entries", force: :cascade do |t|
      t.bigint "user_id", null: false
      t.foreign_key :users, column: :user_id
      t.index ["user_id"]
    end
    RUBY

    subject { Ridgepole::Client }

    it {
      delta = subject.diff(actual_dsl, expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when add index with algorithm: :concurrently' do
    subject { Ridgepole::Client }

    context 'when index does not exist' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "email", null: false
            t.string "name", null: false
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "email", null: false
            t.string "name", null: false
          end

          add_index "users", ["email"], name: "idx_users_email", algorithm: :concurrently
        RUBY
      end

      it 'creates index with algorithm: :concurrently' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          add_index("users", ["email"], **{name: "idx_users_email", algorithm: :concurrently})
        RUBY
      end
    end
    context 'when index exists without algorithm' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "email", null: false
            t.string "name", null: false
          end

          add_index "users", ["email"], name: "idx_users_email"
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "email", null: false
            t.string "name", null: false
          end

          add_index "users", ["email"], name: "idx_users_email", algorithm: :concurrently
        RUBY
      end

      it 'recreates index with algorithm: :concurrently' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to_not be_differ
        expect(delta.script).to be_empty
      end
    end
  end

  context 'when add foreign key with validate: false' do
    subject { Ridgepole::Client }

    context 'when foreign key does not exist' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", validate: false
        RUBY
      end

      it 'creates foreign key with validate: false' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          add_foreign_key("entries", "users", **{validate: false})
        RUBY
      end
    end

    context 'when foreign key exists without validate' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users"
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", validate: false
        RUBY
      end

      it 'does not recreate foreign key just for validate: false' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to_not be_differ
        expect(delta.script).to be_empty
      end
    end

    context 'when foreign key exists with validate: false and DSL implies validated' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", validate: false
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users"
        RUBY
      end

      it 'validates the foreign key instead of DROP + re-ADD' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          validate_foreign_key("entries", "users")
        RUBY
      end
    end

    context 'when foreign key exists with validate: false and DSL specifies validate: true' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", validate: false
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", validate: true
        RUBY
      end

      it 'validates the foreign key instead of DROP + re-ADD' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          validate_foreign_key("entries", "users")
        RUBY
      end
    end

    context 'when foreign key exists with validate: false and a name, and DSL implies validated' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", name: "fk_entries_users", validate: false
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "users", force: :cascade do |t|
            t.string "name", null: false
          end

          create_table "entries", force: :cascade do |t|
            t.bigint "user_id", null: false
          end

          add_foreign_key "entries", "users", name: "fk_entries_users"
        RUBY
      end

      it 'validates the foreign key by name' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          validate_foreign_key("entries", name: "fk_entries_users")
        RUBY
      end
    end
  end

  context 'when add check constraint with validate: false' do
    subject { Ridgepole::Client }

    context 'when check constraint does not exist' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check", validate: false
          end
        RUBY
      end

      it 'creates check constraint with validate: false' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          add_check_constraint("products", "price > 0", **{name: "products_price_check", validate: false})
        RUBY
      end
    end

    context 'when check constraint exists without validate' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check"
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check", validate: false
          end
        RUBY
      end

      it 'does not recreate check constraint just for validate: false' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to_not be_differ
        expect(delta.script).to be_empty
      end
    end

    context 'when check constraint exists with validate: false and DSL implies validated' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check", validate: false
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check"
          end
        RUBY
      end

      it 'validates the check constraint instead of DROP + re-ADD' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          validate_check_constraint("products", name: "products_price_check")
        RUBY
      end
    end

    context 'when check constraint exists with validate: false and DSL specifies validate: true' do
      let(:actual_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check", validate: false
          end
        RUBY
      end

      let(:expected_dsl) do
        <<-RUBY
          create_table "products", force: :cascade do |t|
            t.integer "price", null: false
            t.check_constraint "price > 0", name: "products_price_check", validate: true
          end
        RUBY
      end

      it 'validates the check constraint instead of DROP + re-ADD' do
        delta = subject.diff(actual_dsl, expected_dsl)
        expect(delta).to be_differ
        expect(delta.script).to match_ruby(<<-RUBY)
          validate_check_constraint("products", name: "products_price_check")
        RUBY
      end
    end
  end
end
