# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "employees", comment: "old comment", force: :cascade do |t|
        t.date   "birth_date", null: false
        t.string "first_name", limit: 14, null: false
        t.string "gender", limit: 1, null: false
        t.date   "hire_date", null: false
        t.string "last_name", limit: 16, null: false
      end

      create_table "tenants", force: :cascade, comment: "old comment '" do |t|
      end
    ERB
  end

  let(:expected_dsl) do
    erbh(<<-ERB)
      create_table "employees", comment: "new comment", force: :cascade do |t|
        t.date   "birth_date", null: false
        t.string "first_name", limit: 14, null: false
        t.string "gender", limit: 1, null: false
        t.date   "hire_date", null: false
        t.string "last_name", limit: 16, null: false
      end

      create_table "tenants", force: :cascade, comment: "new comment '" do |t|
      end
    ERB
  end

  before { subject.diff(actual_dsl).migrate }

  context 'when ignore_table_comment option is false' do
    subject { client }

    it {
      allow(Ridgepole::Logger.instance).to receive(:verbose_info)
      expect(Ridgepole::Logger.instance).to receive(:verbose_info).with(<<-MSG)
# Table option changes are ignored on `employees`.
  from: #{{ comment: 'old comment' }}
    to: #{{ comment: 'new comment' }}
      MSG
      expect(Ridgepole::Logger.instance).to receive(:verbose_info).once.with(<<-MSG)
# Table option changes are ignored on `tenants`.
  from: #{{ comment: "old comment '" }}
    to: #{{ comment: "new comment '" }}
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

  context 'when postgresql_change_table_comment option is true' do
    subject { client(postgresql_change_table_comment: true) }

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
