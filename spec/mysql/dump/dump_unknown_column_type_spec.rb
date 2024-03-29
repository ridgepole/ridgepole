# frozen_string_literal: true

describe 'Ridgepole::Client#dump' do
  context 'when there is a tables' do
    before { restore_tables_mysql_unknown_column_type }
    subject { client }

    it {
      expect(subject.dump).to match_fuzzy erbh(<<-ERB)
        create_table "clubs", id: { type: :integer, unsigned: true }, force: :cascade do |t|
          t.string "name", default: "", null: false
          t.index ["name"], name: "idx_name", unique: true
        end
      ERB
    }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).twice
      subject.dump
    }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with('[WARNING] Could not dump table "places" because of following StandardError')
      expect(Ridgepole::Logger.instance).to receive(:warn).with("   Unknown type 'geometry' for column 'location'")
      subject.dump
    }
  end
end
