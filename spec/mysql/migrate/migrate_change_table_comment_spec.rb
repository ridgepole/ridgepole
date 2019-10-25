# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "employees", force: :cascade, comment: "old comment" do |t|
        t.date   "birth_date", null: false
        t.string "first_name", limit: 14, null: false
        t.string "last_name", limit: 16, null: false
        t.string "gender", limit: 1, null: false
        t.date   "hire_date", null: false
      end
    ERB
  end

  let(:expected_dsl) do
    erbh(<<-ERB)
      create_table "employees", force: :cascade, comment: "new comment" do |t|
        t.date   "birth_date", null: false
        t.string "first_name", limit: 14, null: false
        t.string "last_name", limit: 16, null: false
        t.string "gender", limit: 1, null: false
        t.date   "hire_date", null: false
      end
    ERB
  end

  before { subject.diff(actual_dsl).migrate }

  context 'when ignore_table_comment option is false' do
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG)
[WARNING] Table option changes are ignored on `employees`.
  from: {:comment=>"old comment"}
    to: {:comment=>"new comment"}
      MSG
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    }
  end

  context 'when ignore_table_comment option is true' do
    subject { client(ignore_table_comment: true) }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    }
  end

  context 'when mysql_change_table_comment option is true' do
    subject { client(mysql_change_table_comment: true) }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
