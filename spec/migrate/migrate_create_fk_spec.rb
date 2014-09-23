describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create fk' do
    let(:actual_dsl) {
      <<-RUBY
create_table "child", force: true do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

create_table "parent", force: true do |t|
end
      RUBY
    }

    let(:expected_dsl) {
      actual_dsl + (<<-RUBY)

add_foreign_key "child", "parent", name: "child_ibfk_1", dependent: :delete
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_foreigner: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, enable_foreigner: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        remove_foreign_key("child", {:name=>"child_ibfk_1"})
      RUBY
    }

    it {
      delta = client(enable_foreigner: true, bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq actual_dsl.strip_heredoc.strip.delete_empty_lines
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        change_table("child", {:bulk => true}) do |t|
          t.foreign_key("parent", {:name=>"child_ibfk_1", :dependent=>:delete})
        end
      RUBY
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end

  context 'when create fk when create table' do
    let(:dsl) {
      <<-RUBY
create_table "parent", force: true do |t|
end

create_table "child", force: true do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1", dependent: :delete
      RUBY
    }

    let(:sorted_dsl) {
      <<-RUBY
create_table "child", force: true do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

create_table "parent", force: true do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1", dependent: :delete
      RUBY
    }

    subject { client(enable_foreigner: true) }

    it {
      delta = subject.diff(dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.strip).to eq ''
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq sorted_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end
end
