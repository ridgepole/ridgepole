describe Ridgepole::Config do
  def strip_heredoc(str)
    indent = str.lines.first.scan(/^ +/)[0].length
    str.gsub(/^ {#{indent}}/m, '')
  end
  subject { Ridgepole::Config.load(config, env) }

  context 'when passed toplevel yaml' do
    let(:config) {
      strip_heredoc <<-YAML
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
      strip_heredoc <<-YAML
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
      strip_heredoc <<-YAML
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
end
