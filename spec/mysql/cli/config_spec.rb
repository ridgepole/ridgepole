# frozen_string_literal: true

describe Ridgepole::Config do
  subject { Ridgepole::Config.load(config, env, spec_name) }

  let(:spec_name) { '' }

  context 'when passed toplevel yaml' do
    let(:config) do
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog
        username: root
      YAML
    end
    let(:env) { 'development' }
    specify do
      expect(subject['adapter']).to eq 'mysql2'
      expect(subject['encoding']).to eq 'utf8'
      expect(subject['database']).to eq 'blog'
      expect(subject['username']).to eq 'root'
    end
  end

  context 'when passed dynamic yaml' do
    let(:config) do
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog_<%= 1 + 2 %>
        username: user_<%= 3 * 4 %>
      YAML
    end
    let(:env) { 'development' }
    specify do
      expect(subject['adapter']).to eq 'mysql2'
      expect(subject['encoding']).to eq 'utf8'
      expect(subject['database']).to eq 'blog_3'
      expect(subject['username']).to eq 'user_12'
    end
  end

  context 'when passed rails database.yml style yaml' do
    let(:config) do
      <<-YAML.strip_heredoc
        development:
          adapter: sqlspecifye
          database: db/sample.db
        production:
          adapter: mysql2
          encoding: utf8
          database: blog
          username: root
      YAML
    end

    context 'in development env' do
      let(:env) { 'development' }
      specify do
        expect(subject['adapter']).to eq 'sqlspecifye'
        expect(subject['database']).to eq 'db/sample.db'
        expect(subject['username']).to be_nil
      end
    end

    context 'in production env' do
      let(:env) { 'production' }
      specify do
        expect(subject['adapter']).to eq 'mysql2'
        expect(subject['encoding']).to eq 'utf8'
        expect(subject['database']).to eq 'blog'
        expect(subject['username']).to eq 'root'
      end
    end
  end

  context 'when passed yaml file' do
    let(:config) do
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog
        username: root
      YAML
    end
    let(:env) { 'development' }
    it {
      Tempfile.create('database.yml') do |f|
        f.puts config
        f.flush

        expect(subject['adapter']).to eq 'mysql2'
        expect(subject['encoding']).to eq 'utf8'
        expect(subject['database']).to eq 'blog'
        expect(subject['username']).to eq 'root'
      end
    }
  end

  context 'when passed unexisting yaml' do
    let(:config) do
      'database.yml'
    end

    let(:env) { 'development' }

    specify do
      expect do
        subject
      end.to raise_error %(Invalid config: 'scheme' is empty: "database.yml")
    end
  end

  context 'when passed DATABASE_URL' do
    let(:config) { 'mysql2://root:pass@127.0.0.1:3307/blog?pool=5&reaping_frequency=2' }
    let(:env) { 'development' }

    it {
      expect(subject['adapter']).to eq 'mysql2'
      expect(subject['database']).to eq 'blog'
      expect(subject['username']).to eq 'root'
      expect(subject['password']).to eq 'pass'
      expect(subject['port']).to eq 3307
      expect(subject['pool']).to eq '5'
      expect(subject['reaping_frequency']).to eq '2'
    }
  end

  context 'when passed Heroku style DATABASE_URL' do
    let(:config) { 'postgres://root:pass@127.0.0.1:5432/blog' }
    let(:env) { 'development' }

    it {
      expect(subject['adapter']).to eq 'postgresql'
      expect(subject['database']).to eq 'blog'
      expect(subject['username']).to eq 'root'
      expect(subject['password']).to eq 'pass'
      expect(subject['port']).to eq 5432
    }
  end

  context 'when passed DATABASE_URL from ENV' do
    let(:config) { 'env:DATABASE_URL' }
    let(:env) { 'development' }

    before do
      allow(ENV).to receive(:fetch).with('DATABASE_URL').and_return('mysql2://root:pass@127.0.0.1:3307/blog')
    end

    it {
      expect(subject['adapter']).to eq 'mysql2'
      expect(subject['database']).to eq 'blog'
      expect(subject['username']).to eq 'root'
      expect(subject['password']).to eq 'pass'
      expect(subject['port']).to eq 3307
    }
  end

  context 'when passed rails database.yml multiple databases style yaml' do
    let(:config) do
      <<-YAML.strip_heredoc
        development:
          primary:
            adapter: sqlspecifye
            database: db/sample.db
        production:
          primary:
            adapter: mysql2
            encoding: utf8
            database: blog
            username: root
          primary_replica:
            adapter: mysql2
            encoding: utf8
            database: blog
            username: readonly
      YAML
    end

    context 'in development env with primary spec name' do
      let(:env) { 'development' }
      let(:spec_name) { 'primary' }
      specify do
        expect(subject['adapter']).to eq 'sqlspecifye'
        expect(subject['database']).to eq 'db/sample.db'
        expect(subject['username']).to be_nil
      end
    end

    context 'in production env with primary spec name' do
      let(:env) { 'production' }
      let(:spec_name) { 'primary' }
      specify do
        expect(subject['adapter']).to eq 'mysql2'
        expect(subject['encoding']).to eq 'utf8'
        expect(subject['database']).to eq 'blog'
        expect(subject['username']).to eq 'root'
      end
    end

    context 'in production env with primary_replica spec name' do
      let(:env) { 'production' }
      let(:spec_name) { 'primary_replica' }
      specify do
        expect(subject['username']).to eq 'readonly'
      end
    end
  end
end
