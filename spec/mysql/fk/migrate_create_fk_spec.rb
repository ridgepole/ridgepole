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
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "child", "parent", name: "child_ibfk_1"
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
      expect(delta.script).to match_fuzzy <<-RUBY
        add_foreign_key("child", "parent", {:name=>"child_ibfk_1"})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create fk when create table' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end
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

        add_foreign_key "child", "parent", name: "child_ibfk_1"
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

  context 'already defined' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id", unsigned: true
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"

        add_foreign_key "child", "parent", name: "child_ibfk_1"

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end
      ERB
    end

    subject { client }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Foreign Key `child(child_ibfk_1)` already defined')
    }
  end

  context 'when create fk without name' do
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
      erbh(actual_dsl + <<-ERB)
        add_foreign_key "child", "parent"
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
      expect(delta.script).to match_fuzzy <<-RUBY
        add_foreign_key("child", "parent", {})
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'orphan fk' do
    let(:dsl) do
      erbh(<<-ERB)
        add_foreign_key "child", "parent", name: "child_ibfk_1"

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end
      ERB
    end

    subject { client }

    it {
      expect do
        subject.diff(dsl)
      end.to raise_error('Table `child` to create the foreign key is not defined: child_ibfk_1')
    }
  end

  context 'when create fk without any indexes for its column' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
        end

        create_table "child", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
          t.integer "parent_id"
        end
        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    subject { client(dump_without_table_options: false) }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with(<<-MSG).twice
[WARNING] Table `child` has a foreign key on `parent_id` column, but doesn't have any indexes on the column.
          Although an index will be added automatically by InnoDB, please add an index explicitly for your future operations.
      MSG
      subject.diff(dsl).migrate

      expect do
        subject.diff(dsl).migrate
      end.to raise_error(/Mysql2::Error: Cannot drop index/)
    }
  end

  context 'when create fk with first key of multiple column indexes for its column' do
    let(:dsl) do
      erbh(<<-ERB)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
        end

        create_table "child", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
          t.integer "parent_id"
          t.string "name"
          t.index ["parent_id", "name"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end
        add_foreign_key "child", "parent", name: "child_ibfk_1"
      ERB
    end

    subject { client(dump_without_table_options: false) }

    it {
      expect(Ridgepole::Logger.instance).to_not receive(:warn)
      subject.diff(dsl).migrate

      expect { subject.diff(dsl).migrate }.to_not raise_error
    }
  end
end
