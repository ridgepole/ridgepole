# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when an anonymous Schemafile index matches multiple existing DB indexes' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "idx_test", force: :cascade do |t|
          t.integer "col_a", null: false
          t.index ["col_a"], name: "idx_keep_me"
          t.index ["col_a"], name: "idx_remove_me"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "idx_test", force: :cascade do |t|
          t.integer "col_a", null: false
          t.index ["col_a"]
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'warns about ambiguity and keeps the first matching index' do
      expect(Ridgepole::Logger.instance).to receive(:warn).with(
        '[WARNING] Multiple existing indexes on `idx_test` match column ["col_a"]: ' \
        '"idx_keep_me", "idx_remove_me". ' \
        'Ridgepole will keep `idx_keep_me` and remove "idx_remove_me". ' \
        'Specify `name:` explicitly to disambiguate.'
      )

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate

      remaining = subject.dump
      expect(remaining).to include('idx_keep_me')
      expect(remaining).not_to include('idx_remove_me')
    end
  end

  context 'when an anonymous Schemafile index matches exactly one DB index' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "idx_test", force: :cascade do |t|
          t.integer "col_a", null: false
          t.index ["col_a"], name: "idx_keep_me"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "idx_test", force: :cascade do |t|
          t.integer "col_a", null: false
          t.index ["col_a"]
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'does not emit the ambiguity warning' do
      expect(Ridgepole::Logger.instance).not_to receive(:warn)
      subject.diff(expected_dsl)
    end
  end
end
