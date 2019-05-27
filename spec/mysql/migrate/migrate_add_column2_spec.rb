# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column (int/noop) (1)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", limit: 4, null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      expect(sql).to match_fuzzy erbh('ALTER TABLE `dept_emp` ADD `emp_no2` int NOT NULL AFTER `emp_no`')
    }
  end

  context 'when add column (int/noop) (2)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", limit: 3, null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(default_integer_limit: 3) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl.sub(/"emp_no"/, '"emp_no", limit: 3')
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl.sub(/"emp_no"/, '"emp_no", limit: 3')

      expect(sql).to match_fuzzy erbh('ALTER TABLE `dept_emp` ADD `emp_no2` mediumint NOT NULL AFTER `emp_no`')
    }
  end

  context 'when add column (int/noop) (3)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", limit: 3, null: false
          t.integer "emp_no2", limit: 4, null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(default_integer_limit: 3) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl.sub(/"emp_no"/, '"emp_no", limit: 3')
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl.sub(/"emp_no"/, '"emp_no", limit: 3')

      expect(sql).to match_fuzzy erbh('ALTER TABLE `dept_emp` ADD `emp_no2` int NOT NULL AFTER `emp_no`')
    }
  end

  context 'when add column (bigint/noop)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.bigint "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.bigint "emp_no", limit: 9, null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(default_bigint_limit: 9) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      expect(sql).to match_fuzzy erbh('ALTER TABLE `dept_emp` ADD `emp_no2` int NOT NULL AFTER `emp_no`')
    }
  end
end
