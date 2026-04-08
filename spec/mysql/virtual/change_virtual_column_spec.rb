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

  context 'when change virtual column without null option (issue #482) (no change)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`last_name`,`first_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`first_name`)", stored: true
          t.virtual "upper_name", type: :string, as: "upper(`last_name`)", stored: true
          t.string "zip_code"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`first_name`,`last_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`first_name`)", stored: true
          t.virtual "upper_name", type: :string, as: "upper(`last_name`)", stored: true
          t.string "zip_code"
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
          t.virtual "full_name", type: :string, as: "concat(`last_name`,`first_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`first_name`)"
          t.virtual "upper_name", type: :string, as: "upper(`last_name`)", stored: true
          t.string "zip_code"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`last_name`,`first_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`last_name`)"
          t.virtual "upper_name", type: :string, as: "upper(`first_name`)", stored: true
          t.string "zip_code", null: false
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

  context 'when change virtual column without null option (issue #482) (bulk mode)' do
    let(:actual_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`last_name`,`first_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`first_name`)"
          t.virtual "upper_name", type: :string, as: "upper(`last_name`)", stored: true
          t.string "zip_code"
        end
      RUBY
    end

    let(:expected_dsl) do
      <<-RUBY
        create_table "users", force: :cascade do |t|
          t.string "first_name", null: false
          t.virtual "full_name", type: :string, as: "concat(`last_name`,`first_name`)", stored: true
          t.string "last_name", null: false
          t.virtual "name_len", type: :integer, as: "length(`last_name`)"
          t.virtual "upper_name", type: :string, as: "upper(`first_name`)", stored: true
          t.string "zip_code", null: false
        end
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(bulk_change: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      # NOTE: bulk_change does not support generated columns `DEFAULT NULL`.
      expect { delta.migrate }.to raise_error(RuntimeError)
    }
  end

  context 'when generated column expression is normalized by MySQL (issue #680)' do
    let(:expected_dsl) do
      <<-RUBY
        create_table "generated_column_repros", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
          t.datetime "deleted_at"
          t.virtual "active_unique_key", type: :integer, as: "if(`deleted_at` IS NULL,1,NULL)", stored: true
        end
      RUBY
    end

    subject { client(dump_without_table_options: false) }

    it {
      subject.diff(expected_dsl).migrate

      expect(subject.dump).to match_ruby <<-RUBY
        create_table "generated_column_repros", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
          t.virtual "active_unique_key", type: :integer, as: "if((`deleted_at` is null),1,NULL)", stored: true
          t.datetime "deleted_at"
        end
      RUBY

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(delta.script).to eq ''
    }
  end
end
