describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add bigint column' do
    let(:actual_dsl) { '' }

    let(:expected_dsl) {
      if condition(:activerecord_5)
        erbh(<<-EOS)
          create_table "bigint_test", id: false, force: :cascade do |t|
            t.bigint "b"
          end
        EOS
      else
        erbh(<<-EOS)
          create_table "bigint_test", id: false, force: :cascade do |t|
            t.integer "b", limit: 8
          end
        EOS
      end
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when no change' do
    let(:dsl) {
      erbh(<<-EOS)
        create_table "bigint_test", id: false, force: :cascade do |t|
          t.bigint "b"
        end
      EOS
    }

    let(:expected_dsl) {
      if condition(:activerecord_5)
        erbh(<<-EOS)
          create_table "bigint_test", id: false, force: :cascade do |t|
            t.bigint "b"
          end
        EOS
      else
        erbh(<<-EOS)
          create_table "bigint_test", id: false, force: :cascade do |t|
            t.integer "b", limit: 8
          end
        EOS
      end
    }

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
