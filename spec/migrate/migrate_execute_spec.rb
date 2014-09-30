describe 'Ridgepole::Client#diff -> migrate' do
  context 'when execute' do
    let(:dsl) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree
      RUBY
    }

    let(:dsl_with_execute) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree

        execute("ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)") do |c|
          c.raw_connection.query("SELECT 1 FROM information_schema.key_column_usage WHERE TABLE_SCHEMA = '#{TEST_SCHEMA}' AND CONSTRAINT_NAME = 'fk_author' LIMIT 1").each.length.zero?
        end
      RUBY
    }

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl_with_execute)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL

      delta.migrate
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE,
          CONSTRAINT `fk_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end

  context 'when not execute' do
    let(:dsl) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree
      RUBY
    }

    let(:dsl_with_execute) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree

        execute("ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)") do |c|
          c.raw_connection.query("SELECT 1 FROM information_schema.key_column_usage WHERE TABLE_SCHEMA = '#{TEST_SCHEMA}' AND CONSTRAINT_NAME = 'fk_author' LIMIT 1").each.length.zero?
        end
      RUBY
    }

    before { subject.diff(dsl_with_execute).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl_with_execute)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE,
          CONSTRAINT `fk_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL

      migrated, out = delta.migrate
      expect(migrated).to be_falsey
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE,
          CONSTRAINT `fk_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end

  context 'when execute (noop)' do
    let(:dsl) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree
      RUBY
    }

    let(:dsl_with_execute) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree

        execute("ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)") do |c|
          c.raw_connection.query("SELECT 1 FROM information_schema.key_column_usage WHERE TABLE_SCHEMA = '#{TEST_SCHEMA}' AND CONSTRAINT_NAME = 'fk_author' LIMIT 1").each.length.zero?
        end
      RUBY
    }

    before { subject.diff(dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl_with_execute)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL

      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(sql.strip).to eq "ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)"

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end

  context 'when not execute (noop)' do
    let(:dsl) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree
      RUBY
    }

    let(:dsl_with_execute) {
      <<-RUBY
        create_table "authors", force: true do |t|
          t.string "name", null: false
        end

        create_table "books", force: true do |t|
          t.string  "title",                     null: false
          t.integer "author_id", unsigned: true, null: false
        end

        add_index "books", ["author_id"], name: "idx_author_id", using: :btree

        execute("ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)") do |c|
          c.raw_connection.query("SELECT 1 FROM information_schema.key_column_usage WHERE TABLE_SCHEMA = '#{TEST_SCHEMA}' AND CONSTRAINT_NAME = 'fk_author' LIMIT 1").each.length.zero?
        end
      RUBY
    }

    before { subject.diff(dsl_with_execute).migrate }
    subject { client }

    it {
      delta = subject.diff(dsl_with_execute)
      expect(delta.differ?).to be_truthy
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE,
          CONSTRAINT `fk_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL

      migrated, sql = delta.migrate(:noop => true)
      expect(migrated).to be_falsey
      expect(subject.dump.delete_empty_lines).to eq dsl.strip_heredoc.strip.delete_empty_lines

      expect(sql.strip).to eq ""

      expect(show_create_table(:books).strip).to eq <<-SQL.strip_heredoc.strip
        CREATE TABLE `books` (
          `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
          `title` varchar(255) NOT NULL,
          `author_id` int(10) unsigned NOT NULL,
          PRIMARY KEY (`id`),
          KEY `idx_author_id` (`author_id`) USING BTREE,
          CONSTRAINT `fk_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      SQL
    }
  end
end
