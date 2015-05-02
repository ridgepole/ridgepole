if postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change fk' do
    let(:actual_dsl) {
      <<-RUBY
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      RUBY
    }

    let(:sorted_actual_dsl) {
      <<-RUBY
create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "child_ibfk_1", on_delete: :cascade
      RUBY
    }

    let(:expected_dsl) {
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

    before { subject.diff(actual_dsl).migrate }

    subject { client(enable_foreigner: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq sorted_actual_dsl.strip_heredoc.strip.delete_empty_lines
      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq expected_dsl.strip_heredoc.strip.delete_empty_lines
    }
  end
end
end
