# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.1' do
  context 'when add exclusion constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.date "deferrable_valid_from", null: false
          t.date "deferrable_valid_to", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.date "deferrable_valid_from", null: false
          t.date "deferrable_valid_to", null: false
          t.exclusion_constraint "daterange(deferrable_valid_from, deferrable_valid_to) WITH &&", using: :gist, name: "deferrable_date_overlap", deferrable: :immediate
          t.exclusion_constraint "daterange(valid_from, valid_to) WITH &&", using: :gist, name: "date_overlap"
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

  context 'when add exclusion constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.date "deferrable_valid_from", null: false
          t.date "deferrable_valid_to", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.date "deferrable_valid_from", null: false
          t.date "deferrable_valid_to", null: false
          t.exclusion_constraint "daterange(deferrable_valid_from, deferrable_valid_to) WITH &&", using: :gist, name: "deferrable_date_overlap", deferrable: :immediate
          t.exclusion_constraint "daterange(valid_from, valid_to) WITH &&", using: :gist, name: "date_overlap"
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
