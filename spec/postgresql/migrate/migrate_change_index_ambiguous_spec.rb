# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:expected_warning) do
    '[WARNING] Multiple existing indexes on `idx_test` match column ["col_a"]: ' \
      '"idx_keep_me", "idx_remove_me". ' \
      'The choice of which index to keep depends on iteration order; ' \
      'specify `name:` explicitly to disambiguate.'
  end

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

    it 'warns about ambiguity' do
      expect(Ridgepole::Logger.instance).to receive(:warn).with(expected_warning)
      subject.diff(expected_dsl)
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
