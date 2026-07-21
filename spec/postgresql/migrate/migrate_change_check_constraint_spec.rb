# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change check constraint' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 100", name: "value_check"
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

  context 'when change check constraint (merge: true)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 100", name: "value_check"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(merge: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change check constraint from validate: false to validated' do
    let(:base_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
        end
      ERB
    end

    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check", validate: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check"
        end
      ERB
    end

    before do
      # Two-step setup so the check constraint is added via ALTER TABLE
      # (PostgreSQL ignores NOT VALID on inline CREATE TABLE constraints).
      subject.diff(base_dsl).migrate
      subject.diff(actual_dsl).migrate
    end
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_ruby(<<-RUBY)
        validate_check_constraint("clubs", name: "value_check")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when do not change check constraint (but quoted)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint '"value" > 0', name: "value_check"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check"
        end
      ERB
    end

    before { subject.diff(expected_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(actual_dsl)
      expect(delta.differ?).to be_falsey
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
