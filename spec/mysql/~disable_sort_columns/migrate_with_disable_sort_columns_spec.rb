# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table with disable sort columns' do
    let(:actual_dsl) { '' }

    let(:expected_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.date    "to_date", null: false
          t.date    "from_date", null: false
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(disable_sort_columns: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when migrate different column order with disable sort columns (no change)' do
    let(:actual_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.date    "to_date", null: false
          t.date    "from_date", null: false
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(disable_sort_columns: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when add column with disable sort columns (no change)' do
    let(:init_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.date    "birth_date", null: false
          t.date    "to_date", null: false
          t.date    "from_date", null: false
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
        end
      RUBY
    end

    let(:actual_dsl) do
      <<~RUBY
        create_table "dept_emp", force: :cascade do |t|
          t.date    "birth_date", null: false
          t.integer "dept_no", null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(init_dsl).migrate }
    subject { client(disable_sort_columns: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_ruby <<~RUBY
        add_column("dept_emp", "birth_date", :date, **{null: false, after: "id"})
      RUBY
      expect(subject.dump).to match_ruby init_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    }
  end
end
