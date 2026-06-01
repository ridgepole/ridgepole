# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.1' do
  context 'when drop exclusion constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.exclusion_constraint "daterange(valid_from, valid_to) WITH &&", using: :gist, name: "date_overlap"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
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

  context 'when drop exclusion constraint with column' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "reservations", force: :cascade do |t|
          t.daterange "reservation_period", null: false
          t.integer "room_number", null: false
          t.string "guest_name", null: false
          t.exclusion_constraint "reservation_period WITH &&", using: :gist, name: "no_overlapping"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "reservations", force: :cascade do |t|
          t.integer "room_number", null: false
          t.string "guest_name", null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'removes exclusion constraint before removing column' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      # Migration should succeed (will fail if constraints are not removed before columns)
      expect { delta.migrate }.not_to raise_error
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when drop exclusion constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
          t.exclusion_constraint "daterange(valid_from, valid_to) WITH &&", using: :gist, name: "date_overlap"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.date "valid_from", null: false
          t.date "valid_to", null: false
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
