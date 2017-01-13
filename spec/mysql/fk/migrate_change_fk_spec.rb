describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      EOS
    }

    let(:sorted_actual_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id" <%= condition(:activerecord_4) ? ', limit: 4' : '' %>
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id" <%= condition(:activerecord_4) ? ', limit: 4' : '' %>
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", force: :cascade do |t|
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
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end
end
