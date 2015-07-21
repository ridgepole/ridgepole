unless postgresql?
if migration_comments_enabled?
unless mysql_awesome_enabled?
describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (add comment)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false
          t.integer "club_id", limit: 4,     null: false
          t.string  "string",  limit: 255,   null: false
          t.text    "text",    limit: 65535, null: false
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "any comment"
          t.integer "club_id", limit: 4,     null: false, comment: "any comment2"
          t.string  "string",  limit: 255,   null: false, comment: "any comment3"
          t.text    "text",    limit: 65535, null: false, comment: "any comment4"
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end

  context 'when change column (delete comment)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "any comment"
          t.integer "club_id", limit: 4,     null: false, comment: "any comment2"
          t.string  "string",  limit: 255,   null: false, comment: "any comment3"
          t.text    "text",    limit: 65535, null: false, comment: "any comment4"
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false
          t.integer "club_id", limit: 4,     null: false
          t.string  "string",  limit: 255,   null: false
          t.text    "text",    limit: 65535, null: false
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end

  context 'when change column (change comment)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "any comment"
          t.integer "club_id", limit: 4,     null: false, comment: "any comment2"
          t.string  "string",  limit: 255,   null: false, comment: "any comment3"
          t.text    "text",    limit: 65535, null: false, comment: "any comment4"
        end
      RUBY
    }

    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "other comment"
          t.integer "club_id", limit: 4,     null: false, comment: "other comment2"
          t.string  "string",  limit: 255,   null: false, comment: "other comment3"
          t.text    "text",    limit: 65535, null: false, comment: "other comment4"
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end

  context 'when change column (no change comment)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "any comment"
          t.integer "club_id", limit: 4,     null: false, comment: "any comment2"
          t.string  "string",  limit: 255,   null: false, comment: "any comment3"
          t.text    "text",    limit: 65535, null: false, comment: "any comment4"
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff(actual_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
    }
  end

  context 'when create table (with comment)' do
    let(:expected_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade, comment: "table comment" do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "other comment"
          t.integer "club_id", limit: 4,     null: false, comment: "other comment2"
          t.string  "string",  limit: 255,   null: false, comment: "other comment3"
          t.text    "text",    limit: 65535, null: false, comment: "other comment4"
        end
      RUBY
    }

    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.strip).to be_empty
      delta.migrate
      expect(subject.dump).to eq expected_dsl.strip_heredoc.strip
    }
  end

  context 'when drop table (with comment)' do
    let(:actual_dsl) {
      <<-RUBY
        create_table "employee_clubs", force: :cascade, comment: "table comment" do |t|
          t.integer "emp_no",  limit: 4,     null: false, comment: "other comment"
          t.integer "club_id", limit: 4,     null: false, comment: "other comment2"
          t.string  "string",  limit: 255,   null: false, comment: "other comment3"
          t.text    "text",    limit: 65535, null: false, comment: "other comment4"
        end
      RUBY
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client(enable_migration_comments: true) }

    it {
      delta = subject.diff('')
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to eq actual_dsl.strip_heredoc.strip
      delta.migrate
      expect(subject.dump).to be_empty
    }
  end
end
end
end
end
