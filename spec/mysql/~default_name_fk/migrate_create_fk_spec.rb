# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end
      ERB
    end

    let(:expected_dsl) do
      actual_dsl + <<-RUBY
        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client(dump_with_default_fk_name: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true, dump_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        add_foreign_key("child", "parent", **{:name=>"fk_rails_e74ce85cbc"})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create fk when create table' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      ERB
    end

    let(:sorted_dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      ERB
    end

    subject { client(dump_with_default_fk_name: true) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy ''
      delta.migrate
      expect(subject.dump).to match_fuzzy sorted_dsl
    }
  end

  context 'already defined' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id", unsigned: true
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      ERB
    end

    subject { client(dump_with_default_fk_name: true) }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Foreign Key `child(fk_rails_e74ce85cbc)` already defined')
    }
  end

  context 'orphan fk' do
    let(:dsl) do
      erbh(<<-ERB)
        # Define parent before child
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      ERB
    end

    subject { client(dump_with_default_fk_name: true) }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Table `child` to create the foreign key is not defined: fk_rails_e74ce85cbc')
    }
  end
end
