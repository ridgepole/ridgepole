# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", id: :integer, force: :cascade do |t|
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

        create_table "parent", id: :integer, force: :cascade do |t|
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

        create_table "parent", id: :integer, force: :cascade do |t|
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

  context 'when change fk using `t.foreign_key`' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", id: :integer, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
          t.foreign_key "parent", name: "child_ibfk_1", on_delete: :cascade
        end
      ERB
    end

    let(:sorted_actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
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

        create_table "parent", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    let(:expected_dsl_using_t_foreign_key) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
          t.foreign_key "parent", name: "child_ibfk_1"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }

    subject { client }

    it {
      delta = subject.diff(expected_dsl_using_t_foreign_key)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when change fk without name' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "parent", id: :integer, force: :cascade do |t|
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

        create_table "parent", id: :integer, force: :cascade do |t|
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

        create_table "parent", id: :integer, force: :cascade do |t|
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

  context 'when drop/add fk with parent table' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent2_id"
          t.index ["parent2_id"], name: "par2_id"
        end

        create_table "parent2", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent2", name: "child_ibfk_2"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(force_drop_table: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop/add fk with parent table without name' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id"
        end

        create_table "parent", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent2_id"
          t.index ["parent2_id"], name: "par2_id"
        end

        create_table "parent2", id: :integer, force: :cascade do |t|
        end

        add_foreign_key "child", "parent2"
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(force_drop_table: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
