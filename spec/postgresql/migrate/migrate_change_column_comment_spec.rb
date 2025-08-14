# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  let(:actual_dsl) do
    erbh(<<-ERB)
      create_table "users", force: :cascade do |t|
        t.string "name", null: false, comment: "User name"
        t.string "email", null: false, comment: "Email address"
      end
    ERB
  end

  let(:expected_dsl) do
    erbh(<<-ERB)
      create_table "users", force: :cascade do |t|
        t.string "name", null: false, comment: "Full name"
        t.string "email", null: false, comment: "Primary email"
      end
    ERB
  end

  before { subject.diff(actual_dsl).migrate }

  context 'when change column comment only' do
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      script = delta.script
      expect(script).to include('change_column_comment("users", "name", "Full name")')
      expect(script).to include('change_column_comment("users", "email", "Primary email")')
      expect(script).not_to include('change_column("users", "name"')
      expect(script).not_to include('change_column("users", "email"')

      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change column comment with bulk_change' do
    subject { client(bulk_change: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy

      script = delta.script
      expect(script).to include('change_column_comment("users", "name", "Full name")')
      expect(script).to include('change_column_comment("users", "email", "Primary email")')
      expect(script).not_to include('t.change("name"')
      expect(script).not_to include('t.change("email"')

      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when mixed changes' do
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "users", force: :cascade do |t|
          t.string "name", null: false, comment: "Full name"
          t.text "email", null: false, comment: "Primary email"
        end
      ERB
    end

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      script = delta.script
      expect(script).to include('change_column_comment("users", "name", "Full name")')
      expect(script).to include('change_column("users", "email", :text')
      expect(script).not_to include('change_column_comment("users", "email"')

      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when skip_column_comment_change option is true' do
    subject { client(skip_column_comment_change: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
    }
  end
end
