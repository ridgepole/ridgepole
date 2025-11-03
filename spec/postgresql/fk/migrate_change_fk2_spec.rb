# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when specifying fk column name (no changes)' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
          t.foreign_key "parent", column: "parent_id"
        end
      ERB
    end

    before { subject.diff(dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to include(/add_foreign_key "child", "parent"$/)
    }
  end
end
