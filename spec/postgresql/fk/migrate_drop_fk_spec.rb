# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    let(:sorted_actual_dsl) do
      expected_dsl + <<-RUBY
        add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", force: :cascade do |t|
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        remove_foreign_key("child", name: "child_ibfk_1")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop fk when drop table' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id", unsigned: true
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    let(:sorted_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy ''
    }
  end

  context 'when drop fk without name' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent"
      ERB
    end

    let(:sorted_actual_dsl) do
      expected_dsl + <<-RUBY
        add_foreign_key "child", "parent"
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", force: :cascade do |t|
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        remove_foreign_key("child", "parent")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop fk when drop table without name' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id", unsigned: true
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent"
      ERB
    end

    let(:sorted_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy ''
    }
  end
end
