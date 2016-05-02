describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no2", <%= i unsigned(true) + {force: :cascade} %> do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with("[WARNING] No difference of schema configuration for table `employees` but table options differ.")
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!  from: <%= {primary_key: "emp_no"} + unsigned(true) %>!))
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!    to: <%= {primary_key: "emp_no2"} + unsigned(true) %>!))
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy actual_dsl
    }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with("[WARNING] No difference of schema configuration for table `employees` but table options differ.")
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!  from: <%= {primary_key: "emp_no2"} + unsigned(true) %>!))
      expect(Ridgepole::Logger.instance).to receive(:warn).with(erbh(%Q!    to: <%= {primary_key: "emp_no"} + unsigned(true) %>!))
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true)
      expect(delta.differ?).to be_falsey
    }
  end
end
