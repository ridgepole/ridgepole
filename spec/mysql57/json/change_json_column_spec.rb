# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change virtual column / not null -> null' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.json    "attrs", null: false
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.json    "attrs"
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
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

  context 'when change virtual column / json -> string' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.json    "attrs", null: false
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.string  "attrs"
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
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

  context 'when change virtual column / string -> json' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.string  "attrs"
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "books", force: :cascade do |t|
          t.string  "title", null: false
          t.json    "attrs", null: false
          t.index ["title"], name: "index_books_on_title", <%= i cond(5.0, using: :btree) %>
        end
      ERB
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
