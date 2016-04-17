describe 'Ridgepole::Client#diff -> migrate', condition: [:mysql_awesome_enabled, :activerecord_5] do
  context 'when change column (add collation)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false,                 collation: "utf8mb4_bin"
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when change column (delete collation)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false,                 collation: "utf8mb4_bin"
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when change column (change collation)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false,                 collation: "utf8mb4_bin"
        end
      EOS
    }

    let(:expected_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "utf8mb4_bin"} %>
          t.text    "text",    limit: 65535, null: false,                 collation: "ascii_bin"
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy expected_dsl
    }
  end

  context 'when change column (no change collation)' do
    let(:actual_dsl) {
      erbh(<<-EOS)
        create_table "employee_clubs", unsigned: true, force: :cascade do |t|
          t.integer "emp_no",  <%= i limit(4) + {null: false} %>
          t.integer "club_id", <%= i limit(4) + {null: false, unsigned: true} %>
          t.string  "string",  <%= i limit(255) + {null: false, collation: "ascii_bin"} %>
          t.text    "text",    limit: 65535, null: false,                 collation: "utf8mb4_bin"
        end
      EOS
    }

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(actual_dsl)
      expect(delta.differ?).to be_falsey
      expect(subject.dump).to match_fuzzy actual_dsl
      delta.migrate
      expect(subject.dump).to match_fuzzy actual_dsl
    }

    describe '#diff' do
      it {
        Tempfile.open("#{File.basename __FILE__}.#{$$}") do |f|
          f.puts(actual_dsl)
          f.flush

          opts = ['--dump-without-table-options']
          opts << '--enable-mysql-awesome' if condition(:mysql_awesome_enabled)
          out, status = run_ridgepole('--diff', "'#{JSON.dump(conn_spec)}'", f.path, *opts)

          expect(out).to be_empty
          expect(status.success?).to be_truthy
        end
      }
    end
  end
end
