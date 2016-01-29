unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) {
      <<-RUBY
create_table "parent", force: :cascade do |t|
end

create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    let(:sorted_actual_dsl) {
      expected_dsl + (<<-RUBY)

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
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
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(dumb_with_default_fk_name: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump.each_line.select {|i| i !~ /\A\Z/ }.join).to eq expected_dsl.strip_heredoc.strip.each_line.select {|i| i !~ /\A\Z/ }.join
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, default_int_limit: 4, dumb_with_default_fk_name: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        add_foreign_key("child", "parent", {:name=>"fk_rails_e74ce85cbc"})
      RUBY
    }

    it {
      delta = client(bulk_change: true, dumb_with_default_fk_name: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_actual_dsl.strip_heredoc.strip
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        remove_foreign_key("child", {:name=>"fk_rails_e74ce85cbc"})
      RUBY
      delta.migrate
      expect(subject.dump.each_line.select {|i| i !~ /\A\Z/ }.join).to eq expected_dsl.strip_heredoc.strip.each_line.select {|i| i !~ /\A\Z/ }.join
    }
  end

  context 'when drop fk when drop table' do
    let(:dsl) {
      <<-RUBY
create_table "parent", force: :cascade do |t|
end


create_table "child", force: :cascade do |t|
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_id", using: :btree

add_foreign_key "child", "parent", name: "fk_rails_e74ce85cbc"
      RUBY
    }

    let(:sorted_dsl) {
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

    before { subject.diff(dsl).migrate }
    subject { client(dumb_with_default_fk_name: true) }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump.strip).to eq ''
    }
  end
end
end
