# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.1' do
  context 'when drop unique constraint' do
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

  context 'when drop unique constraint with column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "items", force: :cascade do |t|
          t.string "sku", null: false
          t.string "name", null: false
          t.integer "quantity", null: false
          t.unique_constraint ["sku"], name: "unique_sku"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "items", force: :cascade do |t|
          t.string "name", null: false
          t.integer "quantity", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'removes unique constraint before removing column' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      # Migration should succeed (will fail if constraints are not removed before columns)
      expect { delta.migrate }.not_to raise_error
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when drop unique constraint (merge: true)' do
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
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(merge: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsy
    }
  end
end
