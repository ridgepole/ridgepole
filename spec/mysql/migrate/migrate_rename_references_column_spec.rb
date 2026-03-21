# frozen_string_literal: true

# Reproduction test for https://github.com/ridgepole/ridgepole/issues/359
# When renaming a references column with renamed_from, Ridgepole should only
# generate a rename_column and not produce a spurious add_index.
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when rename references column (issue #359)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.bigint "xxx_id"
          t.index ["xxx_id"], name: "index_my_tables_on_xxx_id"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.references :xxx_yyy, renamed_from: 'xxx_id'
        end
      RUBY
    end

    let(:expected_dump) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.bigint "xxx_yyy_id"
          t.index ["xxx_yyy_id"], name: "index_my_tables_on_xxx_yyy_id"
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'migrates without error and produces correct dump' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dump
    end

    it 'does not generate spurious add_index in script' do
      delta = subject.diff(expected_dsl)
      expect(delta.script).not_to include('add_index')
    end
  end

  context 'after renaming references column' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.bigint "xxx_yyy_id"
          t.index ["xxx_yyy_id"], name: "index_my_tables_on_xxx_yyy_id"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.references :xxx_yyy, renamed_from: 'xxx_id'
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
    end
  end

  context 'when rename with index' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.bigint "xxx_id"
          t.index ["xxx_id"], name: "index_my_tables_on_xxx_id"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "my_tables", force: :cascade do |t|
          t.bigint "xxx_yyy_id", renamed_from: "xxx_id"
          t.index ["xxx_yyy_id"], name: "index_my_tables_on_xxx_yyy_id"
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl.sub(', renamed_from: "xxx_id"', '')
    end
  end
end
