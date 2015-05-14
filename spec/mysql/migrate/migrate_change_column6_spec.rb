unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column after id (pk: normal)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", force: :cascade do |t|
          t.date     "birth_date",                    null: false
          t.string   "first_name",      limit: 14,    null: false
          t.string   "last_name",       limit: 16,    null: false
          t.string   "gender",          limit: 1,     null: false
          t.date     "hire_date",                     null: false
          t.datetime "created_at",                    null: false
          t.datetime "updated_at",                    null: false
          t.binary   "registered_name", limit: 65535
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", force: :cascade do |t|
          t.string   "ext_column",      limit: 255, null: false
          t.date     "birth_date",                  null: false
          t.string   "first_name",      limit: 14,  null: false
          t.string   "last_name",       limit: 16,  null: false
          t.string   "gender",          limit: 1,   null: false
          t.date     "hire_date",                   null: false
          t.datetime "created_at",                  null: false
          t.datetime "updated_at",                  null: false
          t.binary   "registered_name", limit: 255
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip

      expect(show_create_table_mysql('employees')).to eq <<-EOS.strip_heredoc.strip
        CREATE TABLE `employees` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `ext_column` varchar(255) NOT NULL,
          `birth_date` date NOT NULL,
          `first_name` varchar(14) NOT NULL,
          `last_name` varchar(16) NOT NULL,
          `gender` varchar(1) NOT NULL,
          `hire_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          `registered_name` varbinary(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      EOS
    }
  end

  context 'when add column after id (pk: emp_id)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.date     "birth_date",                    null: false
          t.string   "first_name",      limit: 14,    null: false
          t.string   "last_name",       limit: 16,    null: false
          t.string   "gender",          limit: 1,     null: false
          t.date     "hire_date",                     null: false
          t.datetime "created_at",                    null: false
          t.datetime "updated_at",                    null: false
          t.binary   "registered_name", limit: 65535
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.string   "ext_column",      limit: 255, null: false
          t.date     "birth_date",                  null: false
          t.string   "first_name",      limit: 14,  null: false
          t.string   "last_name",       limit: 16,  null: false
          t.string   "gender",          limit: 1,   null: false
          t.date     "hire_date",                   null: false
          t.datetime "created_at",                  null: false
          t.datetime "updated_at",                  null: false
          t.binary   "registered_name", limit: 255
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip

      expect(show_create_table_mysql('employees')).to eq <<-EOS.strip_heredoc.strip
        CREATE TABLE `employees` (
          `emp_id` int(11) NOT NULL AUTO_INCREMENT,
          `ext_column` varchar(255) NOT NULL,
          `birth_date` date NOT NULL,
          `first_name` varchar(14) NOT NULL,
          `last_name` varchar(16) NOT NULL,
          `gender` varchar(1) NOT NULL,
          `hire_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          `registered_name` varbinary(255) DEFAULT NULL,
          PRIMARY KEY (`emp_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      EOS
    }
  end

  context 'when add column after id (pk: no pk)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", id: false, force: :cascade do |t|
          t.date     "birth_date",                    null: false
          t.string   "first_name",      limit: 14,    null: false
          t.string   "last_name",       limit: 16,    null: false
          t.string   "gender",          limit: 1,     null: false
          t.date     "hire_date",                     null: false
          t.datetime "created_at",                    null: false
          t.datetime "updated_at",                    null: false
          t.binary   "registered_name", limit: 65535
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", id: false, force: :cascade do |t|
          t.string   "ext_column",      limit: 255, null: false
          t.date     "birth_date",                  null: false
          t.string   "first_name",      limit: 14,  null: false
          t.string   "last_name",       limit: 16,  null: false
          t.string   "gender",          limit: 1,   null: false
          t.date     "hire_date",                   null: false
          t.datetime "created_at",                  null: false
          t.datetime "updated_at",                  null: false
          t.binary   "registered_name", limit: 255
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip

      expect(show_create_table_mysql('employees')).to eq <<-EOS.strip_heredoc.strip
        CREATE TABLE `employees` (
          `ext_column` varchar(255) NOT NULL,
          `birth_date` date NOT NULL,
          `first_name` varchar(14) NOT NULL,
          `last_name` varchar(16) NOT NULL,
          `gender` varchar(1) NOT NULL,
          `hire_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          `registered_name` varbinary(255) DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      EOS
    }
  end

  context 'when add column after id (pk: with pk delta)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", force: :cascade do |t|
          t.date     "birth_date",                    null: false
          t.string   "first_name",      limit: 14,    null: false
          t.string   "last_name",       limit: 16,    null: false
          t.string   "gender",          limit: 1,     null: false
          t.date     "hire_date",                     null: false
          t.datetime "created_at",                    null: false
          t.datetime "updated_at",                    null: false
          t.binary   "registered_name", limit: 65535
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_id", force: :cascade do |t|
          t.string   "ext_column",      limit: 255, null: false
          t.date     "birth_date",                  null: false
          t.string   "first_name",      limit: 14,  null: false
          t.string   "last_name",       limit: 16,  null: false
          t.string   "gender",          limit: 1,   null: false
          t.date     "hire_date",                   null: false
          t.datetime "created_at",                  null: false
          t.datetime "updated_at",                  null: false
          t.binary   "registered_name", limit: 255
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip.sub(', primary_key: "emp_id"', '')

      expect(show_create_table_mysql('employees')).to eq <<-EOS.strip_heredoc.strip
        CREATE TABLE `employees` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `ext_column` varchar(255) NOT NULL,
          `birth_date` date NOT NULL,
          `first_name` varchar(14) NOT NULL,
          `last_name` varchar(16) NOT NULL,
          `gender` varchar(1) NOT NULL,
          `hire_date` date NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          `registered_name` varbinary(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      EOS
    }
  end
end
end
