describe 'Ridgepole::Client#diff -> migrate' do
  context 'when no operation' do
    let(:actual_dsl) { '' }
    let(:expected_dsl) {
      <<-RUBY
        create_table "clubs", force: true do |t|
          t.string "name", default: "", null: false
        end

        add_index "clubs", ["name"], name: "idx_name", unique: true, using: :btree

        create_table "departments", primary_key: "dept_no", force: true do |t|
          t.string "dept_name", limit: 40, null: false
        end

        add_index "departments", ["dept_name"], name: "dept_name", unique: true, using: :btree

        create_table "dept_emp", id: false, force: true do |t|
          t.integer "emp_no",              null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_emp", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_emp", ["emp_no"], name: "emp_no", using: :btree

        create_table "dept_manager", id: false, force: true do |t|
          t.string  "dept_no",   limit: 4, null: false
          t.integer "emp_no",              null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end

        add_index "dept_manager", ["dept_no"], name: "dept_no", using: :btree
        add_index "dept_manager", ["emp_no"], name: "emp_no", using: :btree

        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  unsigned: true, null: false
          t.integer "club_id", unsigned: true, null: false
        end

        add_index "employee_clubs", ["emp_no", "club_id"], name: "idx_emp_no_club_id", using: :btree

        create_table "employees", primary_key: "emp_no", force: true do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

        create_table "salaries", id: false, force: true do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end

        add_index "salaries", ["emp_no"], name: "emp_no", using: :btree

        create_table "titles", id: false, force: true do |t|
          t.integer "emp_no",               null: false
          t.string  "title",     limit: 50, null: false
          t.date    "from_date",            null: false
          t.date    "to_date"
        end

        add_index "titles", ["emp_no"], name: "emp_no", using: :btree
      RUBY
    }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      sql = delta.migrate(:noop => true)
      expect(subject.dump).to eq actual_dsl

      sql = sql.each_line.map {|i| i.strip }.join("\n")

      expect(sql).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `clubs` (`id` int(10) unsigned DEFAULT NULL auto_increment PRIMARY KEY, `name` varchar(255) DEFAULT '' NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `idx_name` USING btree ON `clubs` (`name`)
        CREATE TABLE `departments` (`dept_no` int(10) unsigned DEFAULT NULL auto_increment PRIMARY KEY, `dept_name` varchar(40) NOT NULL) ENGINE=InnoDB
        CREATE UNIQUE INDEX `dept_name` USING btree ON `departments` (`dept_name`)
        CREATE TABLE `dept_emp` (`emp_no` int(10) NOT NULL, `dept_no` varchar(4) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_emp` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_emp` (`emp_no`)
        CREATE TABLE `dept_manager` (`dept_no` varchar(4) NOT NULL, `emp_no` int(10) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `dept_no` USING btree ON `dept_manager` (`dept_no`)
        CREATE  INDEX `emp_no` USING btree ON `dept_manager` (`emp_no`)
        CREATE TABLE `employee_clubs` (`id` int(10) unsigned DEFAULT NULL auto_increment PRIMARY KEY, `emp_no` int(10) unsigned NOT NULL, `club_id` int(10) unsigned NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `idx_emp_no_club_id` USING btree ON `employee_clubs` (`emp_no`, `club_id`)
        CREATE TABLE `employees` (`emp_no` int(10) unsigned DEFAULT NULL auto_increment PRIMARY KEY, `birth_date` date NOT NULL, `first_name` varchar(14) NOT NULL, `last_name` varchar(16) NOT NULL, `gender` varchar(1) NOT NULL, `hire_date` date NOT NULL) ENGINE=InnoDB
        CREATE TABLE `salaries` (`emp_no` int(10) NOT NULL, `salary` int(10) NOT NULL, `from_date` date NOT NULL, `to_date` date NOT NULL) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `salaries` (`emp_no`)
        CREATE TABLE `titles` (`emp_no` int(10) NOT NULL, `title` varchar(50) NOT NULL, `from_date` date NOT NULL, `to_date` date) ENGINE=InnoDB
        CREATE  INDEX `emp_no` USING btree ON `titles` (`emp_no`)
      SQL
    }
  end
end
