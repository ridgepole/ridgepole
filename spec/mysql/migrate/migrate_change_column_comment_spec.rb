# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "users", force: :cascade do |t|
        t.string "name", null: false, comment: "User name"
        t.string "email", null: false, comment: "Email address"
        t.integer "age", null: false, comment: "age"
        t.string "address", null: false, comment: "address"
      end
    ERB
  end

  let(:expected_dsl) do
    erbh(<<-ERB)
      create_table "users", force: :cascade do |t|
        t.string "name", null: false, comment: "Full name"
        t.text "email", null: false, comment: "Primary email"
        t.integer "age", comment: "age"
        t.string "address", null: false, comment: "address"
      end
    ERB
  end

  before { subject.diff(actual_dsl).migrate }

  context 'when change column comment' do
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      expect(delta.script).to match_fuzzy erbh(<<-ERB)
        change_column("users", "email", :text, **#{{ null: false, comment: 'Primary email', default: nil, unsigned: false }})
        change_column("users", "age", :integer, **#{{ comment: 'age', null: true, default: nil, unsigned: false }})
        change_column_comment("users", "name", "Full name")
      ERB

      delta.migrate
      puts subject.dump
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change column comment with bulk_change' do
    subject { client(bulk_change: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      expect(delta.script).to match_fuzzy erbh(<<-ERB)
        change_table("users", bulk: true) do |t|
          t.change("email", :text, **#{{ null: false, comment: 'Primary email', default: nil, unsigned: false }})
          t.change("age", :integer, **#{{ comment: 'age', null: true, default: nil, unsigned: false }})
        end
        change_column_comment("users", "name", "Full name")
      ERB

      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when skip_column_comment_change option is true' do
    subject { client(skip_column_comment_change: true) }

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.string "name", null: false, comment: "Full name"
          t.string "email", null: false, comment: "Primary address"
          t.integer "age", null: false, comment: "age"
          t.string "address", null: false, comment: "address"
        end
      ERB
    end

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
    }
  end
end
