# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate', condition: '>= 7.1' do
  context 'when create composite fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
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

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl

      fk_script = if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.4')
                    'add_foreign_key("child", "parent", **{:column=>["parent_id", "target_date"], :primary_key=>["parent_id", "target_date"], :name=>"fk_parent_child"})'
                  else
                    'add_foreign_key("child", "parent", **{column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"})'
                  end

      expect(delta.script).to match_fuzzy fk_script
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create composite fk using `t.foreign_key`' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
      ERB
    end

    let(:expected_dsl_using_t_foreign_key) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
          t.foreign_key "parent", name: "fk_parent_child", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"]
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl_using_t_foreign_key)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl_using_t_foreign_key)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      fk_script = if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.4')
                    'add_foreign_key("child", "parent", **{:name=>"fk_parent_child", :column=>["parent_id", "target_date"], :primary_key=>["parent_id", "target_date"]})'
                  else
                    'add_foreign_key("child", "parent", **{name: "fk_parent_child", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"]})'
                  end

      expect(delta.script).to match_fuzzy fk_script
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create composite fk when create table' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    let(:sorted_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end

        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
      ERB
    end

    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy ''
      delta.migrate
      expect(subject.dump).to match_fuzzy sorted_dsl
    }
  end

  context 'when drop composite fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end

        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        remove_foreign_key("child", name: "fk_parent_child")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop composite fk using `t.foreign_key`' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
          t.foreign_key "parent", name: "fk_parent_child", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"]
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end
      ERB
    end

    let(:sorted_actual_dsl) do
      expected_dsl + <<-RUBY
        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
      RUBY
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
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
        remove_foreign_key("child", name: "fk_parent_child")
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop composite fk when drop table' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "child_idx"
        end

        create_table "parent", primary_key: ["parent_id", "target_date"], force: :cascade do |t|
          t.integer "parent_id", null: false
          t.date "target_date", null: false
          t.index ["parent_id", "target_date"], name: "parent_idx"
        end

        add_foreign_key "child", "parent", column: ["parent_id", "target_date"], primary_key: ["parent_id", "target_date"], name: "fk_parent_child"
      ERB
    end

    before { subject.diff(dsl).migrate }
    subject { client(force_drop_table: true) }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy ''
    }
  end
end
