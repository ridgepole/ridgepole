# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column to first' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", force: :cascade do |t|
          t.integer "emp_no0", null: false
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
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

      expect(show_create_table_mysql('dept_emp')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `dept_emp` (
          `id` <%= cond('>= 5.1','bigint(20)', 'int(11)') %> NOT NULL AUTO_INCREMENT,
          `emp_no0` int(11) NOT NULL,
          `emp_no` int(11) NOT NULL,
          `dept_no` varchar(4) NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      ERB
    }
  end

  context 'when add column to first (no id)' do
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
      erbh(<<-ERB)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no0", null: false
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
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

      expect(show_create_table_mysql('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `emp_no0` int(11) NOT NULL,
          `emp_no` int(11) NOT NULL,
          `dept_no` varchar(4) NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
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
          t.integer "emp_no0", null: false
          t.string  "dept_no", limit: 4, null: false
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

      expect(show_create_table_mysql('dept_emp')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `dept_emp` (
          `emp_no` <%= cond('>= 5.1','bigint(20)', 'int(11)') %> NOT NULL AUTO_INCREMENT,
          `emp_no0` int(11) NOT NULL,
          `dept_no` varchar(4) NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      ERB
    }
  end

  context 'when add column to first (with multiple pk)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.integer "emp_no0", null: false
          t.string  "dept_no", limit: 4, null: false
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

      expect(show_create_table_mysql('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `emp_no1` int(11) NOT NULL,
          `emp_no2` int(11) NOT NULL,
          `emp_no0` int(11) NOT NULL,
          `dept_no` varchar(4) NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no1`,`emp_no2`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end

  context 'when add column to first (with multiple pk2)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "dept_emp", primary_key: ["emp_no1", "emp_no2"], force: :cascade do |t|
          t.integer "emp_no0", null: false
          t.integer "emp_no1", null: false
          t.integer "emp_no2", null: false
          t.string  "dept_no", limit: 4, null: false
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

      expect(show_create_table_mysql('dept_emp')).to match_fuzzy <<-SQL
        CREATE TABLE `dept_emp` (
          `emp_no0` int(11) NOT NULL,
          `emp_no1` int(11) NOT NULL,
          `emp_no2` int(11) NOT NULL,
          `dept_no` varchar(4) NOT NULL,
          `from_date` date NOT NULL,
          `to_date` date NOT NULL,
          PRIMARY KEY (`emp_no1`,`emp_no2`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end
end
