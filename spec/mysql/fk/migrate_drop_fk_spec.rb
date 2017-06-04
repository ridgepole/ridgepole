describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

    let(:sorted_actual_dsl) {
      expected_dsl + (<<-EOS)

add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        add_foreign_key("child", "parent", {:name=>"child_ibfk_1"})
      EOS
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy sorted_actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        remove_foreign_key("child", {:name=>"child_ibfk_1"})
      EOS
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when drop fk when drop table' do
    let(:dsl) {
      erbh(<<-EOS)
create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end


create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

    let(:sorted_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

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
