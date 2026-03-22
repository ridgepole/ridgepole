# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when timestamp with precision: 6 should not produce spurious diff' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
          t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
          t.timestamp "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(delta.script).to be_nil
    }
  end

  context 'when timestamp with precision: 3 should still produce diff' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP<%= i cond(">= 7.0", "(6)") %>" }
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.timestamp "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP(3)" }
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
    }
  end

  context 'when datetime with precision: 6 should not produce spurious diff' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.datetime "created_at"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "timestamps_test", force: :cascade do |t|
          t.datetime "created_at", precision: 6
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(delta.script).to be_nil
    }
  end
end
