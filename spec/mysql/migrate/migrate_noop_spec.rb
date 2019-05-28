# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when no operation' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    end

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      expect(sql).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `name` varchar(255) DEFAULT '' NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE UNIQUE INDEX `idx_name` USING btree ON `clubs` (`name`)
        CREATE TABLE `departments` (`dept_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `dept_name` varchar(40) NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE UNIQUE INDEX `dept_name` USING btree ON `departments` (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` int NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `dept_no` USING btree ON `dept_emp` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_emp` (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `dept_no` USING btree ON `dept_manager` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_manager` (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `emp_no` int unsigned NOT NULL, `club_id` int unsigned NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `idx_emp_no_club_id` USING btree ON `employee_clubs` (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE TABLE `salaries` (`emp_no` int NOT NULL, `salary` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `emp_no` USING btree ON `salaries` (`emp_no`)
        CREATE TABLE `titles` (`emp_no` int NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `emp_no` USING btree ON `titles` (`emp_no`)
      ERB
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      # XXX:
      expect(sql.delete('`')).to match_fuzzy erbh(<<-ERB).delete('`')
        CREATE TABLE `clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `name` varchar(255) DEFAULT '' NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `clubs` ADD UNIQUE INDEX `idx_name` USING btree (`name`)
        CREATE TABLE `departments` (`dept_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `dept_name` varchar(40) NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `departments` ADD UNIQUE INDEX `dept_name` USING btree (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` int NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `dept_emp` ADD  INDEX `dept_no` USING btree (`dept_no`), ADD  INDEX `emp_no` USING btree (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `dept_manager` ADD  INDEX `dept_no` USING btree (`dept_no`), ADD  INDEX `emp_no` USING btree (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `emp_no` int unsigned NOT NULL, `club_id` int unsigned NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `employee_clubs` ADD  INDEX `idx_emp_no_club_id` USING btree (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE TABLE `salaries` (`emp_no` int NOT NULL, `salary` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `salaries` ADD  INDEX `emp_no` USING btree (`emp_no`)
        CREATE TABLE `titles` (`emp_no` int NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        ALTER TABLE `titles` ADD  INDEX `emp_no` USING btree (`emp_no`)
      ERB
    }
  end

  context 'when no operation' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "dept_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no", limit: 4, null: false
          t.integer "emp_no", limit: 4, null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no", null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "salary", null: false
          t.date    "from_date", null: false
          t.date    "to_date", null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.string  "title", limit: 50, null: false
          t.date    "from_date", null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    end

    subject { client(default_int_limit: 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(noop: true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      expect(sql).to match_fuzzy erbh(<<-ERB)
        CREATE TABLE `clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `name` varchar(255) DEFAULT '' NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE UNIQUE INDEX `idx_name` USING btree ON `clubs` (`name`)
        CREATE TABLE `departments` (`dept_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `dept_name` varchar(40) NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE UNIQUE INDEX `dept_name` USING btree ON `departments` (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` int NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `dept_no` USING btree ON `dept_emp` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_emp` (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `dept_no` USING btree ON `dept_manager` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_manager` (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `emp_no` int unsigned NOT NULL, `club_id` int unsigned NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `idx_emp_no_club_id` USING btree ON `employee_clubs` (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= cond('>= 5.1','bigint NOT NULL', 'int') %> AUTO_INCREMENT PRIMARY KEY, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE TABLE `salaries` (`emp_no` int NOT NULL, `salary` int NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `emp_no` USING btree ON `salaries` (`emp_no`)
        CREATE TABLE `titles` (`emp_no` int NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) <%= cond('< 5.2.0.beta2', 'ENGINE=InnoDB') %>
        CREATE  INDEX `emp_no` USING btree ON `titles` (`emp_no`)
      ERB
    }
  end
end
