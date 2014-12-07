describe 'Ridgepole::Client#diff -> migrate' do
  context 'when database and definition are same (default unsigned / nothing -> unsigned:false)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", unsigned: false,null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip.gsub('unsigned: false,', '')
    }
  end

  context 'when database and definition are same (default null / unsigned:false -> nothing)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", unsigned: false,null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: true do |t|
          t.integer "emp_no",  null: false, unsigned: true
          t.integer "club_id", null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip.gsub('unsigned: false,', '')
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end
end
