# frozen_string_literal: true

describe 'ridgepole --diff CONFIG SCHEMAFILE' do
  let(:other_database) { 'ridgepole_test_other' }

  let(:dsl) do
    <<-RUBY
      create_table "clubs", force: :cascade do |t|
        t.string "name", default: "", null: false
      end
    RUBY
  end

  before do
    system_raise_on_fail(%(#{MYSQL_CLI} -e "DROP DATABASE IF EXISTS \\`#{other_database}\\`; CREATE DATABASE \\`#{other_database}\\`"))
  end

  after do
    system_raise_on_fail(%(#{MYSQL_CLI} -e "DROP DATABASE IF EXISTS \\`#{other_database}\\`"))
  end

  def show_tables(database)
    `#{MYSQL_CLI} -N -e 'SHOW TABLES' #{database}`.split("\n")
  end

  def schemafile(&block)
    Tempfile.open("#{File.basename __FILE__}.#{$PROCESS_ID}") do |f|
      f.puts(dsl)
      f.flush
      block.call(f.path)
    end
  end

  specify 'compares the database with the schemafile' do
    schemafile do |path|
      out, status = run_ridgepole('--diff', "'#{JSON.dump(conn_spec)}'", path)

      # Exit code 1 if there is a difference
      expect(status.success?).to be_falsey

      expect(out).to match_ruby <<-RUBY
        create_table("clubs", **#{{}}) do |t|
          t.column("name", :string, **#{{ default: '', null: false, limit: 255 }})
        end
      RUBY
    end
  end

  specify 'with-apply applies to the database passed to --diff' do
    schemafile do |path|
      out, status = run_ridgepole(
        '-c', "'#{JSON.dump(conn_spec(database: other_database))}'",
        '--diff', "'#{JSON.dump(conn_spec)}'", path, '--with-apply'
      )

      expect(status.success?).to be_truthy
      expect(out).to match(/create_table\("clubs"/)

      # `-c` is not used in diff mode. The connection is established by `--diff`
      expect(show_tables(TEST_SCHEMA)).to eq %w[clubs]
      expect(show_tables(other_database)).to be_empty
    end
  end
end
