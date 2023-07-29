# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop timestamps with index' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
        end
      RUBY
    end

    let(:apply_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
          t.timestamps index: true
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["created_at"], name: "index_clubs_on_created_at"
          t.index ["updated_at"], name: "index_clubs_on_updated_at"
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(apply_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate()
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when add timestamps with index' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
          t.timestamps index: true
        end
      RUBY
    end

    let(:export_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.index ["created_at"], name: "index_clubs_on_created_at"
          t.index ["updated_at"], name: "index_clubs_on_updated_at"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "clubs", force: :cascade do |t|
          t.string "name", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby export_dsl
      delta.migrate()
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
