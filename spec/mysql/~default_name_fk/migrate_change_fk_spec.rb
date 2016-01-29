unless postgresql?
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

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc", on_delete: :cascade
      RUBY
    }

    let(:sorted_actual_dsl) {
      <<-RUBY
create_table "child", force: :cascade do |t|
  t.integer "parent_id", limit: 4
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc", on_delete: :cascade
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
create_table "child", force: :cascade do |t|
  t.integer "parent_id", limit: 4
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

create_table "parent", force: :cascade do |t|
end

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }

    subject { client(dumb_with_default_fk_name: true) }

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
