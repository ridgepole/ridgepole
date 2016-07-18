describe 'Ridgepole::Client#diff -> migrate', condition: [:activerecord_5] do
  context 'when create table' do
    let(:dsl) { '' }

    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
          t.string   "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      EOS
    }

    let(:expected_dsl) { dsl }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
