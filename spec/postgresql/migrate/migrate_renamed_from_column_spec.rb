# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when renamed_from column option is set for new table' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false, renamed_from: "name_old"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.string "name", limit: 255, default: "", null: false
        end
      ERB
    end

    subject { client }

    before { subject.diff(actual_dsl).migrate }

    it 'ignores renamed_form column option' do
      expect(subject.dump).to match_ruby expected_dsl
    end
  end
end
