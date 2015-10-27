unless postgresql?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when default:0 -> (emply)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: false
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,                null: true
          t.float   "salary",    limit: 24,               null: false
          t.date    "from_date",                          null: false
          t.date    "to_date",                            null: false
        end
      RUBY
    }

    let(:result_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
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
      expect(subject.dump).to eq result_dsl.strip_heredoc.strip
    }
  end

  context 'when default:0 -> (emply with null:false)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: false
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  null: false
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
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
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end

  context 'when default:0 -> default:0' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: false
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(actual_dsl)
      expect(delta.differ?).to be_falsey
    }
  end

  context 'when default:0 -> default:0/null:true' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: false
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: true
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    let(:result_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
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
      expect(subject.dump).to eq result_dsl.strip_heredoc.strip
    }
  end

  context 'when default:0/null:true -> default:nil/null:false' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  null: false
          t.float   "salary",    limit: 24, null: false
          t.date    "from_date",            null: false
          t.date    "to_date",              null: false
        end
      RUBY
    }

    let(:result_dsl) {
      <<-RUBY
        create_table "salaries", id: false, force: :cascade do |t|
          t.integer "emp_no",    limit: 4,  default: 0, null: false
          t.float   "salary",    limit: 24,             null: false
          t.date    "from_date",                        null: false
          t.date    "to_date",                          null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      expect(Ridgepole::Logger.instance).to receive(:warn).with('[WARNING] Table `salaries`: `default: nil` is ignored when `null: false`. Please apply twice')
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq result_dsl.strip_heredoc.strip

      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq result_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end
end
end
