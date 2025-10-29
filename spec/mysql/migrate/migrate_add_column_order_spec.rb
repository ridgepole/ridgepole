# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column to first' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.integer "emp_no0", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl

      expect(show_create_table('dept_emp')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `dept_emp` (
          `id` bigint NOT NULL AUTO_INCREMENT,
          `dept_no` varchar NOT NULL,
          `emp_no` int NOT NULL,
          `emp_no0` int NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      ERB
    }
  end

  context 'when add column to first (no id)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.integer "emp_no0", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl

      expect(show_create_table('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `dept_no` varchar NOT NULL,
          `emp_no` int NOT NULL,
          `emp_no0` int NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      SQL
    }
  end

  context 'when add column to first (with pk)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: "emp_no", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: "emp_no", force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no0", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl

      expect(show_create_table('dept_emp')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `dept_emp` (
          `emp_no` bigint NOT NULL AUTO_INCREMENT,
          `dept_no` varchar NOT NULL,
          `emp_no0` int NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      ERB
    }
  end

  context 'when add column to first (with multiple pk)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no0", null: false
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl

      expect(show_create_table('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `dept_no` varchar NOT NULL,
          `emp_no0` int NOT NULL,
          `emp_no1` int NOT NULL,
          `emp_no2` int NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no1`,`emp_no2`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      SQL
    }
  end

  context 'when add column to first (with multiple pk2)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no0", null: false
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl

      expect(show_create_table('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `dept_no` varchar NOT NULL,
          `emp_no0` int NOT NULL,
          `emp_no1` int NOT NULL,
          `emp_no2` int NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no1`,`emp_no2`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      SQL
    }
  end
end
