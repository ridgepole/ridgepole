if postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) {
      <<-RUBY
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

create_table "parent", force: :cascade do |t|
end
      RUBY
    }

    let(:expected_dsl) {
      actual_dsl + (<<-RUBY)

add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        remove_foreign_key("child", {:name=>"child_ibfk_1"})
      RUBY
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        add_foreign_key("child", "parent", {:name=>"child_ibfk_1"})
      RUBY
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'when create fk when create table' do
    let(:dsl) {
      <<-RUBY
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
    }

    let(:sorted_dsl) {
      <<-RUBY
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
    }

    before { client.diff('').migrate }
    subject { client }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.strip).to eq ''
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq sorted_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'already defined' do
    let(:dsl) {
      <<-RUBY
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1"

add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
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
      <<-RUBY
# Define parent before child
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent"
      RUBY
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
      <<-RUBY
# Define parent before child
create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1"
      RUBY
    }

    subject { client }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Table `child` to create the foreign key is not defined: child_ibfk_1')
    }
  end
end
end
