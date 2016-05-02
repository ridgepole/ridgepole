describe 'Ridgepole::Client#diff -> migrate' do
  let(:template_variables) {
    opts = {
      sql_int_type: 'int(11)',
    }

    if condition(:mysql_awesome_enabled, :activerecord_5)
      opts.merge!(
        sql_int_type: 'int'
      )
    end

    opts
  }

  context 'when add column (int/noop) (1)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",             null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      expect(sql).to match_fuzzy erbh("ALTER TABLE `dept_emp` ADD `emp_no2` <%= @sql_int_type %> NOT NULL AFTER `emp_no`", template_variables)
    }
  end

  context 'when add column (int/noop) (2)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",             null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:default_int_limit => 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      expect(sql).to match_fuzzy erbh("ALTER TABLE `dept_emp` ADD `emp_no2` <%= @sql_int_type %> NOT NULL AFTER `emp_no`", template_variables)
    }
  end

  context 'when add column (int/noop) (3)' do
    let(:actual_dsl) {
      erbh(<<-EOS, template_variables)
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    <%= i limit(4) + {null: false} %>
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "dept_emp", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4, null: false
          t.integer "emp_no2",   limit: 4, null: false
          t.string  "dept_no",   limit: 4, null: false
          t.date    "from_date",           null: false
          t.date    "to_date",             null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(:default_int_limit => 11) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl

      expect(sql).to match_fuzzy erbh("ALTER TABLE `dept_emp` ADD `emp_no2` <%= @sql_int_type %> NOT NULL AFTER `emp_no`", template_variables)
    }
  end
end
