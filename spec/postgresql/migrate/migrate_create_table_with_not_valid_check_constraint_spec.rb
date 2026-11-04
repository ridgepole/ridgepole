# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create table with NOT VALID check constraint', condition: '>= 7.1.0' do
    subject { client }

    let(:dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value > 0", name: "value_check", validate: false
          t.check_constraint "value < 100", name: "value_upper_check"
        end
      ERB
    end

    # PostgreSQL ignores NOT VALID on inline CREATE TABLE constraints,
    # so the NOT VALID one must be added via ALTER TABLE to remain NOT VALID.
    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "clubs", force: :cascade do |t|
          t.bigint "value", null: false
          t.check_constraint "value < 100", name: "value_upper_check"
        end

        add_check_constraint "clubs", "value > 0", name: "value_check", validate: false
      ERB
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_ruby(<<-RUBY)
        create_table("clubs", **{}) do |t|
          t.column("value", :"bigint", **{:null=>false})
          t.check_constraint("value < 100", **{:name=>"value_upper_check"})
        end
        add_check_constraint("clubs", "value > 0", **{:name=>"value_check", :validate=>false})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
      expect(subject.diff(dsl).differ?).to be_falsey
    }
  end

  context 'when create table with NOT VALID check constraint (bulk_change)', condition: '>= 7.1.0' do
    subject { client(bulk_change: true) }

    let(:dsl) do
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
        end

        add_check_constraint "clubs", "value > 0", name: "value_check", validate: false
      ERB
    end

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
