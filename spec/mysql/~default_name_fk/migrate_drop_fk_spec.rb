describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    let(:sorted_actual_dsl) {
      expected_dsl + (<<-EOS)
        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
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
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(dump_with_default_fk_name: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true, dump_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        remove_foreign_key("child", {:name=>"fk_rails_e74ce85cbc"})
      EOS
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when drop fk when drop table' do
    let(:dsl) {
      erbh(<<-EOS)
        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    let(:sorted_dsl) {
      erbh(<<-EOS)
        create_table "child", force: :cascade do |t|
          t.integer "parent_id"
          t.index ["parent_id"], name: "par_id", <%= i cond(5.0, using: :btree) %>
        end

        create_table "parent", <%= i cond('>= 5.1',id: :integer) %>, force: :cascade do |t|
        end

        add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    before { subject.diff(dsl).migrate }
    subject { client(dump_with_default_fk_name: true) }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy ''
    }
  end
end
