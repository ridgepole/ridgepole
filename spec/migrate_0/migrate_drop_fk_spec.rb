describe 'Ridgepole::Client#diff -> migrate' do
  context 'when drop fk' do
    let(:actual_dsl) {
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

    let(:sorted_actual_dsl) {
      expected_dsl + (<<-RUBY)

add_foreign_key "child", "parent", name: "child_ibfk_1", dependent: :delete
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
create_table "child", force: true do |t|
  t.integer "parent_id", unsigned: true
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

create_table "parent", force: true do |t|
end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_foreigner: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump.each_line.select {|i| i !~ /\A\Z/ }.join).to eq expected_dsl.strip_heredoc.strip.each_line.select {|i| i !~ /\A\Z/ }.join
    }

    it {
      delta = Ridgepole::Client.diff(actual_dsl, expected_dsl, reverse: true, enable_foreigner: true)
      expect(delta.differ?).to be_truthy
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        add_foreign_key("child", "parent", {:name=>"child_ibfk_1", :dependent=>:delete})
      RUBY
    }

    it {
      delta = client(enable_foreigner: true, bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_actual_dsl.strip_heredoc.strip
      expect(delta.script).to eq <<-RUBY.strip_heredoc.strip
        change_table("child", {:bulk => true}) do |t|
          t.remove_foreign_key({:name=>"child_ibfk_1"})
        end
      RUBY
      delta.migrate
      expect(subject.dump.each_line.select {|i| i !~ /\A\Z/ }.join).to eq expected_dsl.strip_heredoc.strip.each_line.select {|i| i !~ /\A\Z/ }.join
    }
  end

  context 'when drop fk when drop table' do
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

    before { subject.diff(dsl).migrate }
    subject { client(enable_foreigner: true) }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq sorted_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump.strip).to eq ''
    }
  end
end
