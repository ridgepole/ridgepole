# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when add column (ext cols)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "items", force: :cascade do |t|
          t.bigint      "bigint"
          t.bit         "bit", limit: 1
          t.bit_varying "bit varying"
          t.boolean     "boolean"
          t.binary      "bytea"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "items", force: :cascade do |t|
          t.bigint      "bigint"
          t.bit         "bit", limit: 1
          t.bit_varying "bit varying"
          t.boolean     "boolean"
          t.binary      "bytea"
          t.cidr        "cidr"
          t.citext      "citext"
          t.datetime    "created_at", null: false
          t.daterange   "daterange"
          t.text        "description"
          t.hstore      "hstore"
          t.inet        "inet"
          t.int4range   "int4range"
          t.int8range   "int8range"
          t.json        "json"
          t.jsonb       "jsonb"
          t.ltree       "ltree"
          t.macaddr     "macaddr"
          t.money       "money", scale: 2
          t.string      "name"
          t.numrange    "numrange"
          t.point       "point"
          t.integer     "price"
          t.tsrange     "tsrange"
          t.tstzrange   "tstzrange"
          t.tsvector    "tsvector"
          t.datetime    "updated_at", null: false
          t.uuid        "uuid"
          t.xml         "xml"
        end
      RUBY
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
end
