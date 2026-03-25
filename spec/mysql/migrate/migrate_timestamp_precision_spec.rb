# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.0.5' do
  context 'when timestamp with precision: 6 should not produce spurious diff' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", precision: 6, <%= i cond(:mysql57, "null: false") %>, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
          t.timestamp "updated_at", precision: 6, <%= i cond(:mysql57, "null: false") %>, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when datetime with precision: 6 should not produce spurious diff' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.datetime "created_at", <%= i cond(">= 7.0", { precision: 6 }) %>, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when timestamp with precision: 3 should still produce diff' do
    let(:create_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", precision: 6, <%= i cond(:mysql57, "null: false") %>, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    let(:change_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", precision: 3, <%= i cond(:mysql57, "null: false") %>, default: -> { "CURRENT_TIMESTAMP(3)" }
        end
      ERB
    end

    before { subject.diff(create_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(change_dsl)
      expect(delta.differ?).to be_truthy
    }
  end
end
