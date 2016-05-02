describe 'Ridgepole::Client#diff -> migrate' do
  let(:template_variables) {
    opts = {
      sql_int_pk_type: 'int(11) auto_increment PRIMARY KEY',
      sql_int_type: 'int(11)',
      sql_uint_type: 'int(11)',
    }

    if condition(:mysql_awesome_enabled)
      opts.merge!(
        sql_int_pk_type: 'int PRIMARY KEY AUTO_INCREMENT',
        sql_int_type: 'int',
        sql_uint_type: 'int unsigned'
      )
    end

    if condition(:activerecord_5)
      opts.merge!(
        sql_int_pk_type: 'int AUTO_INCREMENT PRIMARY KEY',
        sql_int_type: 'int',
        sql_uint_type: 'int unsigned',
        using_btree: 'USING btree'
      )
    end

    opts
  }

  context 'when no operation' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) {
      <<-EOS
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",              null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      EOS
    }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      expect(sql).to match_fuzzy erbh(<<-EOS, template_variables)
        CREATE TABLE `clubs` (`id` <%= @sql_int_pk_type %>, `name` varchar(255) DEFAULT '' NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `idx_name` USING btree ON `clubs` (`name`)
        CREATE TABLE `departments` (`dept_no` <%= @sql_int_pk_type %>, `dept_name` varchar(40) NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `dept_name` USING btree ON `departments` (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` <%= @sql_int_type %> NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_emp` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_emp` (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_manager` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_manager` (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= @sql_int_pk_type %>, `emp_no` <%= @sql_uint_type %> NOT NULL, `club_id` <%= @sql_uint_type %> NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `idx_emp_no_club_id` USING btree ON `employee_clubs` (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= @sql_int_pk_type %>, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) ENGINE=InnoDB
        CREATE TABLE `salaries` (`emp_no` <%= @sql_int_type %> NOT NULL, `salary` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `salaries` (`emp_no`)
        CREATE TABLE `titles` (`emp_no` <%= @sql_int_type %> NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `titles` (`emp_no`)
      EOS
    }

    it {
      delta = client(:bulk_change => true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      # XXX:
      expect(sql.gsub('`', '')).to match_fuzzy erbh(<<-EOS, template_variables).gsub('`', '')
        CREATE TABLE `clubs` (`id` <%= @sql_int_pk_type %>, `name` varchar(255) DEFAULT '' NOT NULL) ENGINE=InnoDB
        ALTER TABLE `clubs` ADD UNIQUE INDEX `idx_name` <%= @using_btree %> (`name`)
        CREATE TABLE `departments` (`dept_no` <%= @sql_int_pk_type %>, `dept_name` varchar(40) NOT NULL) ENGINE=InnoDB
        ALTER TABLE `departments` ADD UNIQUE INDEX `dept_name` <%= @using_btree %> (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` <%= @sql_int_type %> NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        ALTER TABLE `dept_emp` ADD  INDEX `dept_no` <%= @using_btree %> (`dept_no`), ADD  INDEX `emp_no` <%= @using_btree %> (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        ALTER TABLE `dept_manager` ADD  INDEX `dept_no` <%= @using_btree %> (`dept_no`), ADD  INDEX `emp_no` <%= @using_btree %> (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= @sql_int_pk_type %>, `emp_no` <%= @sql_uint_type %> NOT NULL, `club_id` <%= @sql_uint_type %> NOT NULL) ENGINE=InnoDB
        ALTER TABLE `employee_clubs` ADD  INDEX `idx_emp_no_club_id` <%= @using_btree %> (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= @sql_int_pk_type %>, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) ENGINE=InnoDB
        CREATE TABLE `salaries` (`emp_no` <%= @sql_int_type %> NOT NULL, `salary` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        ALTER TABLE `salaries` ADD  INDEX `emp_no` <%= @using_btree %> (`emp_no`)
        CREATE TABLE `titles` (`emp_no` <%= @sql_int_type %> NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) ENGINE=InnoDB
        ALTER TABLE `titles` ADD  INDEX `emp_no` <%= @using_btree %> (`emp_no`)
      EOS
    }
  end

  context 'when no operation' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) {
      <<-EOS
        create_table "clubs", force: :cascade do |t|
          t.string "name", default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: :cascade do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: :cascade do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",    limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false, unsigned: true
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: :cascade do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      EOS
    }

    subject { client(:default_int_limit => 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      expect(sql).to match_fuzzy erbh(<<-EOS, template_variables)
        CREATE TABLE `clubs` (`id` <%= @sql_int_pk_type %>, `name` varchar(255) DEFAULT '' NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `idx_name` USING btree ON `clubs` (`name`)
        CREATE TABLE `departments` (`dept_no` <%= @sql_int_pk_type %>, `dept_name` varchar(40) NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `dept_name` USING btree ON `departments` (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` <%= @sql_int_type %> NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_emp` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_emp` (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_manager` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_manager` (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` <%= @sql_int_pk_type %>, `emp_no` <%= @sql_uint_type %> NOT NULL, `club_id` <%= @sql_uint_type %> NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `idx_emp_no_club_id` USING btree ON `employee_clubs` (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` <%= @sql_int_pk_type %>, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) ENGINE=InnoDB
        CREATE TABLE `salaries` (`emp_no` <%= @sql_int_type %> NOT NULL, `salary` <%= @sql_int_type %> NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `salaries` (`emp_no`)
        CREATE TABLE `titles` (`emp_no` <%= @sql_int_type %> NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `titles` (`emp_no`)
      EOS
    }
  end
end
