# frozen_string_literal: true

describe 'Ridgepole::Client#dump' do
  let(:actual_dsl) do
    erbh(<<-'ERB')
      create_table "books", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='\"london\" bridge \"is\" falling \"down\"'" do |t|
        t.string   "title", null: false
        t.integer  "author_id", null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    ERB
  end

  context 'when without table options' do
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "books", <%= i cond('>= 5.1',id: :bigint) %>, unsigned: true, force: :cascade, comment: "\\"london\\" bridge \\"is\\" falling \\"down\\"" do |t|
          t.string   "title", null: false
          t.integer  "author_id", null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
