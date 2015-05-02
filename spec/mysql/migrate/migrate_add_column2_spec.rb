unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column (int/noop) (1)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",             null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip

      sql = sql.each_line.map {|i| i.strip }.join("\n")
      expect(sql).to eq("ALTER TABLE `dept_emp` ADD `emp_no2` int#{if_mysql_awesome_enabled('', '(11)')} NOT NULL AFTER `emp_no`")
    }
  end

  context 'when add column (int/noop) (2)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",             null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:default_int_limit => 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip

      sql = sql.each_line.map {|i| i.strip }.join("\n")
      expect(sql).to eq("ALTER TABLE `dept_emp` ADD `emp_no2` int#{if_mysql_awesome_enabled('', '(11)')} NOT NULL AFTER `emp_no`")
    }
  end

  context 'when add column (int/noop) (3)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",   limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:default_int_limit => 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip

      sql = sql.each_line.map {|i| i.strip }.join("\n")
      expect(sql).to eq("ALTER TABLE `dept_emp` ADD `emp_no2` int#{if_mysql_awesome_enabled('', '(11)')} NOT NULL AFTER `emp_no`")
    }
  end
end
end
