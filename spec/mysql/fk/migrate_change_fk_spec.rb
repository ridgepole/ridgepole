describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      EOS
    }

    let(:sorted_actual_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

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

  context 'when change fk without name' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", on_delete: :cascade
      EOS
    }

    let(:sorted_actual_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", on_delete: :cascade
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
      EOS
    }

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
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent2_id"
          t.index ["parent2_id"], name: "par2_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent2", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent2", name: "child_ibfk_2"
      EOS
    }

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

  context 'when drop/add fk with parent table without name' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent"
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent2_id"
          t.index ["parent2_id"], name: "par2_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent2", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent2"
      EOS
    }

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
end
