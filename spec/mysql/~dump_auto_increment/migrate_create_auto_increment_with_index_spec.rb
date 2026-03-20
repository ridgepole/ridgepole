# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table with non-PK auto_increment column and index (without --create-table-with-index)' do
    let(:actual_dsl) { '' }

    let(:expected_dsl) do
      <<-RUBY
        create_table "sample_table", id: { type: :string, limit: 26 }, force: :cascade do |t|
          t.datetime "created_at", null: false
          t.bigint "partition_key", null: false, unsigned: true, auto_increment: true
          t.datetime "updated_at", null: false
          t.index ["partition_key", "id"], name: "idx_partition_key_and_id", unique: true
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(mysql_dump_auto_increment: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      # The auto_increment column's index should be inside CREATE TABLE
      expect(delta.script).to match_fuzzy <<-RUBY
        create_table("sample_table", **{id: { type: :string, limit: 26}}) do |t|
          t.column("created_at", :"datetime", **{null: false})
          t.column("partition_key", :"bigint", **{null: false, unsigned: true, auto_increment: true, limit: 8})
          t.column("updated_at", :"datetime", **{null: false})
          t.index(["partition_key", "id"], **{name: "idx_partition_key_and_id", unique: true})
        end
      RUBY

      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
