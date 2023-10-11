# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.1' do
  context 'when change unique constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "tenant_id", null: false
          t.unique_constraint ["tenant_id"], name: "unique_tenant_id", deferrable: :immediate
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "tenant_id", null: false
          t.unique_constraint ["tenant_id"], name: "unique_tenant_id", deferrable: :deferred
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change unique constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "tenant_id", null: false
          t.unique_constraint ["tenant_id"], name: "unique_tenant_id", deferrable: :immediate
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "tenant_id", null: false
          t.unique_constraint ["tenant_id"], name: "unique_tenant_id", deferrable: :deferred
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(merge: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
