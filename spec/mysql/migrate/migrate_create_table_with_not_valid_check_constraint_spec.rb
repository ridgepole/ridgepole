# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: [[:mysql80]] do
  context 'when create table with validate: false check constraint' do
    subject { client }

    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check", validate: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "`value` > 0", name: "value_check"
        end
      ERB
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to include 't.check_constraint("value > 0"'
      expect(delta.script).not_to include 'add_check_constraint'
      # Adding a check constraint via ALTER TABLE does not support ALGORITHM=INPLACE.
      delta.migrate(alter_extra: 'ALGORITHM=INPLACE, LOCK=NONE')
      expect(subject.dump).to match_ruby expected_dsl
      expect(subject.diff(dsl).differ?).to be_falsey
    }
  end
end
