# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change virtual column' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string   "title"
          t.virtual "title_length", type: :integer, null: false, as: "length(`title`)", stored: true
          t.virtual "upper_title", type: :string, null: false, as: "upper(`title`)"
          t.index ["title"], name: "index_books_on_title"
          t.index ["title_length"], name: "index_books_on_title_length"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "books", force: :cascade do |t|
          t.string   "title"
          t.virtual "title_length", type: :integer, null: false, as: "upper(`title`)", stored: true
          t.virtual "upper_title", type: :string, null: false, as: "length(`title`)"
          t.index ["title"], name: "index_books_on_title"
          t.index ["title_length"], name: "index_books_on_title_length"
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

  context 'when change virtual column without null option (issue #482)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`last_name`,_utf8mb4\\' \\',`first_name`)", stored: true
          t.string "last_name", null: false
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`first_name`,_utf8mb4\\' \\',`last_name`)", stored: true
          t.string "last_name", null: false
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
