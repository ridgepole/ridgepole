describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

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
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", force: :cascade do |t|
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
      expect(subject.dump).to match_fuzzy expected_dsl
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4, dump_with_default_fk_name: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        add_foreign_key("child", "parent", {:name=>"fk_rails_e74ce85cbc"})
      EOS
    }

    it {
      delta = client(bulk_change: true, dump_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        remove_foreign_key("child", {:name=>"fk_rails_e74ce85cbc"})
      EOS
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when drop fk when drop table' do
    let(:dsl) {
      erbh(<<-EOS)
create_table "parent", force: :cascade do |t|
end


create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    let(:sorted_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", force: :cascade do |t|
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
