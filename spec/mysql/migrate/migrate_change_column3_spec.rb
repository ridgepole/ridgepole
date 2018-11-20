describe 'Ridgepole::Client#diff -> migrate' do
  context 'when use timestamps (no change)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name", limit: 16, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.timestamps
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use timestamps (change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.timestamps
        end
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name", limit: 16, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when use references (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.index "products_id"
          t.index "user_id"
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.references :products, :user
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references with polymorphic (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.string "products_type"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.string "user_type"
          t.index ["products_type", "products_id"]
          t.index ["user_type", "user_id"]
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.references :products, :user, polymorphic: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references with unsigned polymorphic (no change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id", unsigned: true
          t.string "products_type"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id", unsigned: true
          t.string "user_type"
          t.index ["products_type", "products_id"]
          t.index ["user_type", "user_id"]
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.references :products, :user, unsigned: true, polymorphic: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when use references (change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.references :products, :user
        end
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.index ["products_id"], name: "index_employees_on_products_id", <%= i cond(5.0, using: :btree) %>
          t.index ["user_id"], name: "index_employees_on_user_id", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when use references with polymorphic (change)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      ERB
    end

    let(:dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.references :products, :user, polymorphic: true
        end
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.<%= cond('>= 5.1','bigint', 'integer') %> "products_id"
          t.string "products_type"
          t.<%= cond('>= 5.1','bigint', 'integer') %> "user_id"
          t.string "user_type"
          t.index ["products_type", "products_id"], name: "index_employees_on_products_type_and_products_id", <%= i cond(5.0, using: :btree) %>
          t.index ["user_type", "user_id"], name: "index_employees_on_user_type_and_user_id", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
