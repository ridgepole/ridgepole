# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (boolean without limit)' do
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
          t.boolean  "registered"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name", limit: 16, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.boolean  "registered"
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

  context 'when change column (boolean with limit)' do
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
          t.boolean  "registered"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "last_name", limit: 16, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.boolean  "registered", limit: 1
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
end
