describe Ridgepole::Config do
  subject { Ridgepole::Config.load(config, env) }

  context 'when passed toplevel yaml' do
    let(:config) {
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog
        username: root
      YAML
    }
    let(:env) { 'development' }
    it {
      expect(subject['adapter']).to eq "mysql2"
      expect(subject['encoding']).to eq "utf8"
      expect(subject['database']).to eq "blog"
      expect(subject['username']).to eq "root"
    }
  end

  context 'when passed dynamic yaml' do
    let(:config) {
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog_<%= 1 + 2 %>
        username: user_<%= 3 * 4 %>
      YAML
    }
    let(:env) { 'development' }
    it {
      expect(subject['adapter']).to eq "mysql2"
      expect(subject['encoding']).to eq "utf8"
      expect(subject['database']).to eq "blog_3"
      expect(subject['username']).to eq "user_12"
    }
  end

  context 'when passed rails database.yml style yaml' do
    let(:config) {
      <<-YAML.strip_heredoc
        development:
          adapter: sqlite
          database: db/sample.db
        production:
          adapter: mysql2
          encoding: utf8
          database: blog
          username: root
      YAML
    }

    context 'in development env' do
      let(:env) { 'development' }
      it {
        expect(subject['adapter']).to eq "sqlite"
        expect(subject['database']).to eq "db/sample.db"
        expect(subject['username']).to be_nil
      }
    end

    context 'in production env' do
      let(:env) { 'production' }
      it {
        expect(subject['adapter']).to eq "mysql2"
        expect(subject['encoding']).to eq "utf8"
        expect(subject['database']).to eq "blog"
        expect(subject['username']).to eq "root"
      }
    end
  end

  context 'when passed yaml file' do
    let(:config) {
      <<-YAML.strip_heredoc
        adapter: mysql2
        encoding: utf8
        database: blog
        username: root
      YAML
    }
    let(:env) { 'development' }
    it {
      Tempfile.create("database.yml") do |f|
        f.puts config
        f.flush

        expect(subject['adapter']).to eq "mysql2"
        expect(subject['encoding']).to eq "utf8"
        expect(subject['database']).to eq "blog"
        expect(subject['username']).to eq "root"
      end
    }
  end

  context 'when passed unexisting yaml' do
    let(:config) {
      'database.yml'
    }

    let(:env) { 'development' }

    it {
      expect {
        subject
      }.to raise_error 'Invalid config: "database.yml"'
    }
  end

  context 'when passed DATABASE_URL' do
    let(:config) { 'mysql2://root:1234@127.0.0.1/blog' }
    let(:env) { 'development' }

    it {
      expect(subject['adapter']).to eq "mysql2"
      expect(subject['database']).to eq "blog"
      expect(subject['username']).to eq "root"
      expect(subject['password']).to eq "1234"
    }
  end
end
