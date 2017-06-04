describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
      EOS
    }

    let(:expected_dsl) {
      erbh(actual_dsl + <<-EOS)

add_foreign_key "child", "parent", name: "child_ibfk_1"
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        remove_foreign_key("child", {:name=>"child_ibfk_1"})
      EOS
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        add_foreign_key("child", "parent", {:name=>"child_ibfk_1"})
      EOS
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when create fk when create table' do
    let(:dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

add_foreign_key "child", "parent", name: "child_ibfk_1"

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
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
    let(:dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

add_foreign_key "child", "parent", name: "child_ibfk_1"

add_foreign_key "child", "parent", name: "child_ibfk_1"

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
      EOS
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Foreign Key `child(child_ibfk_1)` already defined')
    }
  end

  context 'no name' do
    let(:dsl) {
      erbh(<<-EOS)
create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

<%= add_index "child", ["parent_id"], {name: "par_id"} + cond('5.0', using: :btree) %>

add_foreign_key "child", "parent"

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
      EOS
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Foreign key name in `child` is undefined')
    }
  end

  context 'orphan fk' do
    let(:dsl) {
      erbh(<<-EOS)
add_foreign_key "child", "parent", name: "child_ibfk_1"

create_table "parent", <%= i cond('5.1', id: :integer) %>, force: :cascade do |t|
end
      EOS
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Table `child` to create the foreign key is not defined: child_ibfk_1')
    }
  end
end
