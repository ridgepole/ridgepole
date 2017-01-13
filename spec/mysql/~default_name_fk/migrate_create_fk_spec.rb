describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) {
      erbh(<<-EOS)
create_table "child", <%= i unsigned(true) + {force: :cascade} %> do |t|
  t.integer "parent_id", <%= i limit(4) + unsigned(true) %>
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", <%= i unsigned(true) + {force: :cascade} %> do |t|
end
      EOS
    }

    let(:expected_dsl) {
      actual_dsl + (<<-EOS)

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(dump_with_default_fk_name: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4, dump_with_default_fk_name: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to match_fuzzy <<-EOS
        remove_foreign_key("child", {:name=>"fk_rails_e74ce85cbc"})
      EOS
    }

    it {
      delta = client(bulk_change: true, dump_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      expect(delta.script).to match_fuzzy <<-EOS
        add_foreign_key("child", "parent", {:name=>"fk_rails_e74ce85cbc"})
      EOS
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when create fk when create table' do
    let(:dsl) {
      erbh(<<-EOS)
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    let(:sorted_dsl) {
      erbh(<<-EOS)

create_table "child", force: :cascade do |t|
  t.integer "parent_id", <%= i limit(4) %>
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

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
    let(:dsl) {
      erbh(<<-EOS)
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    subject { client(dump_with_default_fk_name: true) }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Foreign Key `child(fk_rails_e74ce85cbc)` already defined')
    }
  end

  context 'no name' do
    let(:dsl) {
      erbh(<<-EOS)
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

<%= add_index "child", ["parent_id"], name: "par_id", using: :btree %>

add_foreign_key "child", "parent"
      EOS
    }

    subject { client(dump_with_default_fk_name: true) }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Foreign key name in `child` is undefined')
    }
  end

  context 'orphan fk' do
    let(:dsl) {
      erbh(<<-EOS)
# Define parent before child
create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      EOS
    }

    subject { client(dump_with_default_fk_name: true) }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Table `child` to create the foreign key is not defined: fk_rails_e74ce85cbc')
    }
  end
end
