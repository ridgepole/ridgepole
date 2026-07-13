# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.0' do
  context 'when add timestamptz column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
          t.timestamptz "created_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
          t.timestamptz "updated_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
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

  context 'when drop timestamptz column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
          t.timestamptz "created_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
          t.timestamptz "updated_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
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

  context 'when change timestamptz column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
          t.datetime "created_at", <%= i cond("< 8.2.0.alpha", { precision: nil }) %>, null: false
          t.datetime "updated_at", <%= i cond("< 8.2.0.alpha", { precision: nil }) %>, null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.date "birth_date"
          t.timestamptz "created_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
          t.timestamptz "updated_at", <%= i cond(">= 8.2.0.alpha", { precision: 6 }) %>, null: false
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
end
