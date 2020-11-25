# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change column (add collation)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false, collation: "utf8mb4_bin"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when change column (delete collation)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false, collation: "utf8mb4_bin"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when change column (change collation)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false, collation: "utf8mb4_bin"
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "utf8mb4_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false, collation: "ascii_bin"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    end
  end

  context 'when change column (no change collation)' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "employee_clubs", <%= i cond('>= 5.1', id: :bigint) %>, unsigned: true, force: :cascade do |t|
          t.integer "emp_no", null: false
          t.integer "club_id", null: false, unsigned: true
          t.string  "string", null: false, collation: "ascii_bin"
          t.text    "text", <%= i cond(5.0, limit: 65535) %>, null: false, collation: "utf8mb4_bin"
        end
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    specify do
      delta = subject.diff(actual_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl
    end

    describe '#diff' do
      specify do
        Tempfile.open("#{File.basename __FILE__}.#{$PROCESS_ID}") do |f|
          f.puts(actual_dsl)
          f.flush

          opts = ['--dump-without-table-options']
          out, status = run_ridgepole('--diff', "'#{JSON.dump(conn_spec)}'", f.path, *opts)

          # v6.0.3 is the oldest version that doesn't produce any kwargs warnings with Ruby 2.7
          if condition('< 6.0.3')
            # https://github.com/jeremyevans/ruby-warning/blob/1.1.0/lib/warning.rb#L18
            out = out.lines.grep_v(/: warning: (?:Using the last argument (?:for `.+' )?as keyword parameters is deprecated; maybe \*\* should be added to the call|Passing the keyword argument (?:for `.+' )?as the last hash parameter is deprecated|Splitting the last argument (?:for `.+' )?into positional and keyword parameters is deprecated|The called method (?:`.+' )?is defined here)\n\z/).join
          end

          expect(out).to be_empty
          expect(status.success?).to be_truthy
        end
      end
    end
  end
end
