# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when rename table with column addition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "user_comments", force: :cascade, renamed_from: "comments" do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
          t.string "status"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'should only rename the table, not add the column' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy <<-RUBY
        create_table "user_comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      RUBY
      expect(subject.dump).not_to match_fuzzy <<-RUBY
        t.string "status"
      RUBY
    end
  end

  context 'when rename table with index addition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "user_comments", force: :cascade, renamed_from: "comments" do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
          t.index ["article_id"], name: "index_article_id"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'should only rename the table, not add the index' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy <<-RUBY
        create_table "user_comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      RUBY
      expect(subject.dump).not_to match_fuzzy <<-RUBY
        t.index ["article_id"], name: "index_article_id"
      RUBY
    end
  end

  context 'when rename table with column type change' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "user_comments", force: :cascade, renamed_from: "comments" do |t|
          t.string "commenter"
          t.text   "body"
          t.bigint "article_id"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'should only rename the table, not change the column type' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy <<-RUBY
        create_table "user_comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
        end
      RUBY
      expect(subject.dump).not_to match_fuzzy <<-RUBY
        t.bigint "article_id"
      RUBY
    end
  end

  context 'when rename table with foreign key addition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "articles", force: :cascade do |t|
          t.string "title"
        end

        create_table "comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
          t.index ["article_id"], name: "index_article_id"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "articles", force: :cascade do |t|
          t.string "title"
        end

        create_table "user_comments", force: :cascade, renamed_from: "comments" do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
          t.index ["article_id"], name: "index_article_id"
        end

        add_foreign_key "user_comments", "articles", name: "fk_comments_articles"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it 'should only rename the table, not add the foreign key' do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy <<-RUBY
        create_table "articles", force: :cascade do |t|
          t.string "title"
        end

        create_table "user_comments", force: :cascade do |t|
          t.string "commenter"
          t.text   "body"
          t.integer "article_id"
          t.index ["article_id"], name: "index_article_id"
        end
      RUBY
      expect(subject.dump).not_to match_fuzzy <<-RUBY
        add_foreign_key "user_comments", "articles", name: "fk_comments_articles"
      RUBY
    end
  end
end
