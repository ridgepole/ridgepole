unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end

      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employees", primary_key: "emp_no2"#{unsigned_if_enabled}, force: :cascade do |t|
          t.date   "birth_date",            null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name",  limit: 16, null: false
          t.string "gender",     limit: 1,  null: false
          t.date   "hire_date",             null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with('[WARNING] Table `employees` options cannot be changed')
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
    }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with('[WARNING] Table `employees` options cannot be changed')
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true)
      expect(delta.differ?).to be_falsey
    }
  end
end
end
