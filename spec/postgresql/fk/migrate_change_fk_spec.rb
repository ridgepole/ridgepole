# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      ERB
    end

    let(:sorted_actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
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
  end

  context 'when change fk from validate: false to validated', condition: '>= 7.1.0' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", validate: false
      ERB
    end

    let(:sorted_actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", validate: false
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_ruby(<<-RUBY)
        validate_foreign_key("child", "parent")
      RUBY
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change fk with column from validate: false to validated and fk with default column references the same table', condition: '>= 7.1.0' do
    let(:tables_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.integer "other_parent_id"
          t.index ["other_parent_id"], name: "other_par_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end
      ERB
    end

    let(:actual_dsl) do
      tables_dsl + <<-RUBY
        add_foreign_key "child", "parent"
        add_foreign_key "child", "parent", column: "other_parent_id", validate: false
      RUBY
    end

    let(:expected_dsl) do
      tables_dsl + <<-RUBY
        add_foreign_key "child", "parent"
        add_foreign_key "child", "parent", column: "other_parent_id"
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_ruby(<<-RUBY)
        validate_foreign_key("child", "parent", column: "other_parent_id")
      RUBY
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
      expect(subject.diff(expected_dsl).differ?).to be_falsey
    }
  end

  context 'when change fk without name' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        add_foreign_key "child", "parent", on_delete: :cascade
      ERB
    end

    let(:sorted_actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent", on_delete: :cascade
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
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
  end
end
