if postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    default: 0, null: false
          t.integer "salary",                null: false
          t.date    "from_date",             null: false
          t.date    "to_date",               null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    null: false
          t.integer "salary",    null: false
          t.date    "from_date", null: false
          t.date    "to_date",   null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip #.gsub(/(\s*,\s*unsigned: false)?\s*,\s*null: true/, '')
    }
  end
end
end
