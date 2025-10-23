# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column after id (pk: normal)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name"
          t.datetime "updated_at", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "ext_column", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name", limit: 255
          t.datetime "updated_at", null: false
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

      expect(show_create_table('employees')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `employees` (
          `id` bigint NOT NULL AUTO_INCREMENT,
          `birth_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `ext_column` varchar NOT NULL,
          `first_name` varchar NOT NULL,
          `gender` varchar NOT NULL,
          `hire_date` date NOT NULL,
          `last_name` varchar NOT NULL,
          `registered_name` varbinary DEFAULT NULL,
          `updated_at` datetime NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      ERB
    }
  end

  context 'when add column after id (pk: emp_id)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name"
          t.datetime "updated_at", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "ext_column", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name", limit: 255
          t.datetime "updated_at", null: false
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

      expect(show_create_table('employees')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `employees` (
          `emp_id` bigint NOT NULL AUTO_INCREMENT,
          `birth_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `ext_column` varchar NOT NULL,
          `first_name` varchar NOT NULL,
          `gender` varchar NOT NULL,
          `hire_date` date NOT NULL,
          `last_name` varchar NOT NULL,
          `registered_name` varbinary DEFAULT NULL,
          `updated_at` datetime NOT NULL,
          PRIMARY KEY (`emp_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      ERB
    }
  end

  context 'when add column after id (pk: no pk)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", id: false, force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name"
          t.datetime "updated_at", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", id: false, force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "ext_column", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name", limit: 255
          t.datetime "updated_at", null: false
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

      expect(show_create_table('employees')).to match_fuzzy <<-SQL
        CREATE TABLE `employees` (
          `birth_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `ext_column` varchar NOT NULL,
          `first_name` varchar NOT NULL,
          `gender` varchar NOT NULL,
          `hire_date` date NOT NULL,
          `last_name` varchar NOT NULL,
          `registered_name` varbinary DEFAULT NULL,
          `updated_at` datetime NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      SQL
    }
  end

  context 'when add column after id (pk: with pk delta)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employees", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name"
          t.datetime "updated_at", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.date     "birth_date", null: false
          t.datetime "created_at", null: false
          t.string   "ext_column", null: false
          t.string   "first_name", limit: 14, null: false
          t.string   "gender", limit: 1, null: false
          t.date     "hire_date", null: false
          t.string   "last_name", limit: 16, null: false
          t.binary   "registered_name", limit: 255
          t.datetime "updated_at", null: false
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
      expect(subject.dump).to match_ruby expected_dsl.sub(/, *primary_key: *"emp_id"/, '')

      expect(show_create_table('employees')).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `employees` (
          `id` bigint NOT NULL AUTO_INCREMENT,
          `birth_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `ext_column` varchar NOT NULL,
          `first_name` varchar NOT NULL,
          `gender` varchar NOT NULL,
          `hire_date` date NOT NULL,
          `last_name` varchar NOT NULL,
          `registered_name` varbinary DEFAULT NULL,
          `updated_at` datetime NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
      ERB
    }
  end
end
