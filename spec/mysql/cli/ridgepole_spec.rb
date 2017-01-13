describe 'ridgepole' do
  let(:differ) { false }
  let(:conf) { "'" + JSON.dump(conn_spec) + "'" }

  def conn_spec_str(database)
    ActiveSupport::HashWithIndifferentAccess.new(conn_spec(database: database)).inspect
  end

  context 'when help' do
    it do
      out, status = run_cli(:args => ['-h'])
      out = out.gsub(/Usage: .*\n/, '')

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        -c, --config CONF_OR_FILE
        -E, --env ENVIRONMENT
        -a, --apply
        -m, --merge
        -f, --file SCHEMAFILE
            --dry-run
            --table-options OPTIONS
            --alter-extra ALTER_SPEC
            --external-script SCRIPT
            --bulk-change
            --default-bool-limit LIMIT
            --default-int-limit LIMIT
            --default-float-limit LIMIT
            --default-string-limit LIMIT
            --default-text-limit LIMIT
            --default-binary-limit LIMIT
            --pre-query QUERY
            --post-query QUERY
        -e, --export
            --split
            --split-with-dir
        -d, --diff DSL1 DSL2
            --reverse
            --with-apply
        -o, --output SCHEMAFILE
        -t, --tables TABLES
            --ignore-tables TABLES
            --enable-mysql-awesome
            --mysql-use-alter
            --dump-without-table-options
            --dump-with-default-fk-name
            --index-removed-drop-column
        -r, --require LIBS
            --log-file LOG_FILE
            --verbose
            --debug
        -v, --version
       EOS
    end
  end

  context 'when export' do
    it 'not split' do
      out, status = run_cli(:args => ['-c', conf, '-e', conf, conf])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        # Export Schema
        Ridgepole::Client#dump
      EOS
    end

    it 'not split with outfile' do
      Tempfile.open("#{File.basename __FILE__}.#{$$}") do |f|
        out, status = run_cli(:args => ['-c', conf, '-e', '-o', f.path])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
          Export Schema to `#{f.path}`
          Ridgepole::Client#dump
        EOS
      end
    end

    it 'not split with output stdout' do
      out, status = run_cli(:args => ['-c', conf, '-e', '-o', '-'])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        # Export Schema
        Ridgepole::Client#dump
      EOS
    end

    it 'split' do
      out, status = run_cli(:args => ['-c', conf, '-e', '--split'])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        Export Schema
        Ridgepole::Client#dump
          write `Schemafile`
      EOS
    end

    it 'split with outdir' do
      Tempfile.open("#{File.basename __FILE__}.#{$$}") do |f|
        out, status = run_cli(:args => ['-c', conf, '-e', '--split', '-o', f.path, conf, conf])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
          Export Schema
          Ridgepole::Client#dump
            write `#{f.path}`
        EOS
      end
    end
  end

  context 'when apply' do
    it 'apply' do
      out, status = run_cli(:args => ['-c', conf, '-a'])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        Apply `Schemafile`
        Ridgepole::Client#diff
        Ridgepole::Delta#differ?
        Ridgepole::Delta#migrate
        No change
      EOS
    end

    it 'apply with conf file' do
      Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
        conf_file.puts <<-EOS
          adapter: mysql2
          database: ridgepole_test_for_conf_file
        EOS
        conf_file.flush

        out, status = run_cli(:args => ['-c', conf_file.path, '-a', '--debug'])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test_for_conf_file"}, {:dry_run=>false, :debug=>true}])
          Apply `Schemafile`
          Ridgepole::Client#diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#migrate
          No change
        EOS
      end
    end

    it 'apply with conf file (production)' do
      Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
        conf_file.puts <<-EOS
          development:
            adapter: mysql2
            database: ridgepole_development
          production:
            adapter: mysql2
            database: ridgepole_production
        EOS
        conf_file.flush

        out, status = run_cli(:args => ['-c', conf_file.path, '-a', '--debug'])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_development"}, {:dry_run=>false, :debug=>true}])
          Apply `Schemafile`
          Ridgepole::Client#diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#migrate
          No change
        EOS
      end
    end

    it 'dry-run' do
      out, status = run_cli(:args => ['-c', conf, '-a', '--dry-run'])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>true, :debug=>false}])
        Apply `Schemafile` (dry-run)
        Ridgepole::Client#diff
        Ridgepole::Delta#differ?
        No change
      EOS
    end

    context 'when differ true' do
      let(:differ) { true }

      it 'apply' do
        out, status = run_cli(:args => ['-c', conf, '-a'])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
          Apply `Schemafile`
          Ridgepole::Client#diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#migrate
        EOS
      end

      it 'dry-run' do
        out, status = run_cli(:args => ['-c', conf, '-a', '--dry-run'])

        expect(status.success?).to be_truthy
        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>true, :debug=>false}])
          Apply `Schemafile` (dry-run)
          Ridgepole::Client#diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#script
          Ridgepole::Delta#script
          create_table :table do
          end

          Ridgepole::Delta#migrate
          # create_table :table do
          # end
        EOS
      end
    end
  end

  context 'when diff' do
    it do
      out, status = run_cli(:args => ['-c', conf, '-d', conf, conf])

      expect(status.success?).to be_truthy
      expect(out).to match_fuzzy <<-EOS
        Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        Ridgepole::Client.diff([#{conn_spec_str("ridgepole_test")}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
        Ridgepole::Delta#differ?
      EOS
    end

    context 'when differ true' do
      let(:differ) { true }

      it do
        out, status = run_cli(:args => ['-c', conf, '-d', conf, conf])

        # Exit code 1 if there is a difference
        expect(status.success?).to be_falsey

        expect(out).to match_fuzzy <<-EOS
          Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
          Ridgepole::Client.diff([#{conn_spec_str("ridgepole_test")}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
          Ridgepole::Delta#differ?
          Ridgepole::Delta#script
          Ridgepole::Delta#script
          create_table :table do
          end

          Ridgepole::Delta#migrate
          # create_table :table do
          # end
        EOS
      end
    end

    context 'when config file' do
      it '.yml' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
          conf_file.puts <<-EOS
            adapter: mysql2
            database: ridgepole_test_for_conf_file
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf_file.path, conf])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([{"adapter"=>"mysql2", "database"=>"ridgepole_test_for_conf_file"}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end

      it '.yml (file2)' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
          conf_file.puts <<-EOS
            adapter: mysql2
            database: ridgepole_test_for_conf_file
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf, conf_file.path])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([#{conn_spec_str("ridgepole_test")}, {"adapter"=>"mysql2", "database"=>"ridgepole_test_for_conf_file"}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end

      it '.yml (development)' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
          conf_file.puts <<-EOS
            development:
              adapter: mysql2
              database: ridgepole_development
            production:
              adapter: mysql2
              database: ridgepole_production
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf_file.path, conf])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([{"adapter"=>"mysql2", "database"=>"ridgepole_development"}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end

      it '.yml (production)' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yml']) do |conf_file|
          conf_file.puts <<-EOS
            development:
              adapter: mysql2
              database: ridgepole_development
            production:
              adapter: mysql2
              database: ridgepole_production
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf_file.path, conf, '-E', :production])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([{"adapter"=>"mysql2", "database"=>"ridgepole_production"}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end

      it '.yaml' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.yaml']) do |conf_file|
          conf_file.puts <<-EOS
            adapter: mysql2
            database: ridgepole_test_for_conf_file
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf_file.path, conf])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([{"adapter"=>"mysql2", "database"=>"ridgepole_test_for_conf_file"}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end

      it '.rb' do
        Tempfile.open(["#{File.basename __FILE__}.#{$$}", '.rb']) do |conf_file|
          conf_file.puts <<-EOS
            create_table :table do
            end
          EOS
          conf_file.flush

          out, status = run_cli(:args => ['-c', conf, '-d', conf_file.path, conf])

          expect(status.success?).to be_truthy

          expect(out).to match_fuzzy <<-EOS
            Ridgepole::Client#initialize([#{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Client.diff([#{conf_file.path}, #{conn_spec_str("ridgepole_test")}, {:dry_run=>false, :debug=>false}])
            Ridgepole::Delta#differ?
          EOS
        end
      end
    end
  end
end
