describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column (ext cols)' do
    let(:actual_dsl) {
      <<-EOS
        create_table "items", force: :cascade do |t|
          t.string   "name"
          t.integer  "price"
          t.text     "description"
          t.datetime "created_at",  null: false
          t.datetime "updated_at",  null: false
        end
      EOS
    }

    let(:expected_dsl) {
      <<-EOS
        create_table "items", force: :cascade do |t|
          t.string      "name"
          t.integer     "price"
          t.text        "description"
          t.datetime    "created_at",                      null: false
          t.datetime    "updated_at",                      null: false
          t.daterange   "daterange"
          t.numrange    "numrange"
          t.tsrange     "tsrange"
          t.tstzrange   "tstzrange"
          t.int4range   "int4range"
          t.int8range   "int8range"
          t.binary      "bytea"
          t.boolean     "boolean"
          t.bigint      "bigint"
          t.xml         "xml"
          t.tsvector    "tsvector"
          t.hstore      "hstore"
          t.inet        "inet"
          t.cidr        "cidr"
          t.macaddr     "macaddr"
          t.uuid        "uuid"
          t.json        "json"
          t.jsonb       "jsonb"
          t.ltree       "ltree"
          t.citext      "citext"
          t.point       "point"
          t.bit         "bit",         limit: 1
          t.bit_varying "bit varying"
          t.money       "money",                 scale: 2
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      if condition(:activerecord_4)
        expected_dsl.sub!('t.bigint      "bigint"', 't.integer     "bigint",      limit: 8')
      end
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
