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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(dumb_with_default_fk_name: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4, dumb_with_default_fk_name: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        remove_foreign_key("child", {:name=>"fk_rails_e74ce85cbc"})
      RUBY
    }

    it {
      delta = client(bulk_change: true, dumb_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        add_foreign_key("child", "parent", {:name=>"fk_rails_e74ce85cbc"})
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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    before { client.diff('').migrate }
    subject { client(dumb_with_default_fk_name: true) }

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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    subject { client(dumb_with_default_fk_name: true) }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Foreign Key `child(fk_rails_e74ce85cbc)` already defined')
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

    subject { client(dumb_with_default_fk_name: true) }

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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    subject { client(dumb_with_default_fk_name: true) }

    it {
      expect {
        subject.diff(dsl)
      }.to raise_error('Table `child` to create the foreign key is not defined: fk_rails_e74ce85cbc')
    }
  end
end
end
