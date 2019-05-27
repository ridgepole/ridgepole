# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add bigint column' do
    let(:actual_dsl) { '' }

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "bigint_test", id: false, force: :cascade do |t|
          t.bigint "b"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when no change' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "bigint_test", id: false, force: :cascade do |t|
          t.bigint "b"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "bigint_test", id: false, force: :cascade do |t|
          t.bigint "b"
        end
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
