# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop check constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 100", name: "value_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
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

  context 'when drop check constraint with column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "products", force: :cascade do |t|
          t.string "name", null: false
          t.integer "price", null: false
          t.integer "quantity", null: false
          t.check_constraint "price > 0", name: "price_positive"
          t.check_constraint "quantity >= 0", name: "quantity_non_negative"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "products", force: :cascade do |t|
          t.string "name", null: false
          t.integer "quantity", null: false
          t.check_constraint "quantity >= 0", name: "quantity_non_negative"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'removes check constraint before removing column' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      # Migration should succeed (will fail if constraints are not removed before columns)
      expect { delta.migrate }.not_to raise_error
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when drop check constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 100", name: "value_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
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
