# Ridgepole

Ridgepole is a tool to manage DB schema.

It defines DB schema using [Rails DSL](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps), and updates DB schema according to DSL.
(like Chef/Puppet)

[![Gem Version](https://badge.fury.io/rb/ridgepole.svg)](http://badge.fury.io/rb/ridgepole)<!--
[![Unstable Version](https://img.shields.io/badge/unstable-0.7.5.beta2-green.svg?longCache=true&style=flat)](https://rubygems.org/gems/ridgepole/versions/0.7.5.beta2)
-->
[![Build Status](https://travis-ci.org/winebarrel/ridgepole.svg?branch=0.7)](https://travis-ci.org/winebarrel/ridgepole)
[![Coverage Status](https://coveralls.io/repos/github/winebarrel/ridgepole/badge.svg?branch=0.7)](https://coveralls.io/github/winebarrel/ridgepole?branch=0.7)

<details><summary>ChangeLog</summary>

* `>= 0.4.8`
  * `activerecord-mysql-unsigned` is now optional. Please pass `--enable-mysql-unsigned` after you install [activerecord-mysql-unsigned](https://github.com/waka/activerecord-mysql-unsigned) if you want to use.
  * Please pass `--enable-foreigner` after you install [foreigner](https://github.com/matthuhiggins/foreigner) if you want to use the foreign key.
* `>= 0.4.11`
  * Add `--enable-mysql-pkdump` option.
* `>= 0.4.12`
  * Fix `activerecord-mysql-unsigned` version: `~> 0.2.0`
* `>= 0.5.0`
  * Fix `activerecord-mysql-unsigned` version: `~> 0.3.1`
* `>= 0.5.1`
  * Add `--enable-migration-comments` option ([migration_comments](https://github.com/pinnymz/migration_comments) is required)
  * Fix rails version `< 4.2.0`
* `>= 0.5.2`
  * Add `--enable-mysql-awesome` option ([activerecord-mysql-awesome](https://github.com/kamipo/activerecord-mysql-awesome) is required `>= 0.0.3`)
  * It is not possible to enable both `--enable-mysql-awesome` and `--enable-migration-comments`, `--enable-mysql-awesome` and `--enable-mysql-unsigned`, `--enable-mysql-awesome` and `--enable-mysql-pkdump`
  * Fix foreigner version `<= 1.7.1`
* `>= 0.6.0`
  * Fix rails version `~> 4.2.1`
  * Disable following libraries support:
    * activerecord-mysql-unsigned
    * migration_comments
    * foreigner
  * Disable sqlite support
  * Add PostgreSQL test
  * Remove `--mysql-awesome-unsigned-pk` option
* `>= 0.6.1`
  * Support [PostgreSQL columns](https://github.com/winebarrel/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L79)
* `>= 0.6.3`
  * Fix `default` option ([pull#48](https://github.com/winebarrel/ridgepole/pull/48))
  * Add `--enable-migration-comments` option ([pull#50](https://github.com/winebarrel/ridgepole/pull/50))
  * Disable `rename_table_indexes`
* `>= 0.6.4`
  * Execute sql using external script ([pull#56](https://github.com/winebarrel/ridgepole/pull/56))
  * Add `--mysql-use-alter` option
  * Add `--alter-extra` option
  * Add `--dump-with-default-fk-name` option
  * Support `t.index` ([pull#64](https://github.com/winebarrel/ridgepole/pull/64))
  * Remove migration_comments
  * Fix foreign key apply order
* `>= 0.6.5`
  * Fix rails version `'>= 4.2', '< 6'`
  * Support new types ([pull#84](https://github.com/winebarrel/ridgepole/pull/84))
  * Support `default: -> { ... }` ([pull#85](https://github.com/winebarrel/ridgepole/pull/85))
  * Support DDL Comment (Rails5 only)
  * Output schema diff when pass `--verbose`
  * Support composite primary key (Rails5 only / [pull#97](https://github.com/winebarrel/ridgepole/pull/97))
* `>= 0.6.6`
  * Use `t.column` for migration ([pull#114](https://github.com/winebarrel/ridgepole/pull/114))
  * Support DATABASE_URL format ([pull#118](https://github.com/winebarrel/ridgepole/pull/118))
  * Add Ruby2.4 CI ([pull#119](https://github.com/winebarrel/ridgepole/pull/119))
* `>= 0.7.0`
  * Remove Rails 4.x support
  * Add Rails 5.1 support
  * Remove `--enable-mysql-awesome` option
  * Add `--skip-drop-table` option
  * Support foreign key without name
  * Support MySQL JSON Type and Generated Columns
  * Add `--mysql-change-table-options` option
  * Pass config from env
  * Fix change fk order
  * Add `--check-relation-type` option
  * Add `--skip-column-comment-change` option
  * Add `--default-bigint-limit` option
  * Add `--ignore-table-comment` option
* `>= 0.7.1`
  * Remove `--reverse` option
  * Add `--allow-pk-change` option
  * Add `--create-table-with-index` option
  * Add `--mysql-dump-auto-increment` option (`rails >= 5.1`)
* `>= 0.7.2`
  * Support Rails 5.2
* `>= 0.7.3`
  * Add `--mysql-change-table-comment option` ([pull#166](https://github.com/winebarrel/ridgepole/pull/166))
  * Refactoring with RuboCop
  * Support primary key adding/dropping ([issue#246](https://github.com/winebarrel/ridgepole/issues/246))
* `>= 0.7.4`
  * Fix `add_foreign_key` options ([issue#250](https://github.com/winebarrel/ridgepole/issues/250))
* `>= 0.7.5`
  * Fix polymorphic options ([pull#263](https://github.com/winebarrel/ridgepole/pull/263))
  * Fix `--mysql-use-alter` option ([pull#246](https://github.com/winebarrel/ridgepole/pull/264))
  * Fix Database URI parsing ([pull#265](https://github.com/winebarrel/ridgepole/pull/265))
</details>

## Installation

Add this line to your application's Gemfile:

    gem 'ridgepole'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ridgepole

## Omnibus Package (deb/rpm)

see https://github.com/winebarrel/ridgepole/releases.

### Install from rpm

```sh
sudo dpkg -i ridgepole_x.x.x+xxx-x_amd64.deb
sudo apt install build-essential libmysqlclient-dev
sudo /opt/ridgepole/embedded/bin/gem install mysql2
```

### Install from rpm

```sh
sudo yum install ridgepole-x.x.x+xxx-x.el7.x86_64.rpm
sudo yum install make gcc mariadb-devel
sudo /opt/ridgepole/embedded/bin/gem install mysql2
```

## Help
```
Usage: ridgepole [options]
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
        --default-bigint-limit LIMIT
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
        --with-apply
    -o, --output SCHEMAFILE
    -t, --tables TABLES
        --ignore-tables REGEX_LIST
        --mysql-use-alter
        --dump-without-table-options
        --dump-with-default-fk-name
        --index-removed-drop-column
        --skip-drop-table
        --mysql-change-table-options
        --mysql-change-table-comment
        --check-relation-type DEF_PK
        --ignore-table-comment
        --skip-column-comment-change
        --create-table-with-index
        --mysql-dump-auto-increment
    -r, --require LIBS
        --log-file LOG_FILE
        --verbose
        --debug
        --[no-]color
    -v, --version
```

## Usage

```sh
$ git init
Initialized empty Git repository in ...

$ cat config.yml
adapter: mysql2
encoding: utf8
database: blog
username: root

$ ridgepole -c config.yml --export -o Schemafile
# or `ridgepole -c '{adapter: mysql2, database: blog}' ...`
# or `ridgepole -c 'mysql2://root:pass@127.0.0.1:3306/blog' ...`
# or `export DB_URL='mysql2://...'; ridgepole -c env:DB_URL ...`
Export Schema to `Schemafile`

$ cat Schemafile
create_table "articles", force: :cascade do |t|
  t.string   "title"
  t.text     "text"
  t.datetime "created_at"
  t.datetime "updated_at"
end

$ git add .
$ git commit -m 'first commit'  -a
[master (root-commit) a6c2d31] first commit
 2 files changed, 10 insertions(+)
 create mode 100644 Schemafile
 create mode 100644 config.yml

$ vi Schemafile
$ git diff
diff --git a/Schemafile b/Schemafile
index f5848b9..c266fed 100644
--- a/Schemafile
+++ b/Schemafile
@@ -1,6 +1,7 @@
 create_table "articles", force: :cascade do |t|
   t.string   "title"
   t.text     "text"
+  t.text     "author"
   t.datetime "created_at"
   t.datetime "updated_at"
 end

$ ridgepole -c config.yml --apply --dry-run
Apply `Schemafile` (dry-run)
add_column("articles", "author", :text, {:after=>"text"})

# ALTER TABLE `articles` ADD `author` text AFTER `text`

$ ridgepole -c config.yml --apply
Apply `Schemafile`
-- add_column("articles", "author", :text, {:after=>"text"})
   -> 0.0202s
```

## Rename
```ruby
create_table "articles", force: :cascade do |t|
  t.string   "title"
  t.text     "desc", renamed_from: "text"
  t.text     "author"
  t.datetime "created_at"
  t.datetime "updated_at"
end

create_table "user_comments", force: :cascade, renamed_from: "comments" do |t|
  t.string   "commenter"
  t.text     "body"
  t.integer  "article_id"
  t.datetime "created_at"
  t.datetime "updated_at"
end
```

## Foreign Key
```ruby
create_table "parent", force: :cascade do |t|
end

create_table "child", id: false, force: :cascade do |t|
  t.integer "id"
  t.integer "parent_id"
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1"
```

## Collation/Charset
You can use the column collation by passing `--enable-mysql-awesome` ([activerecord-mysql-awesome](https://github.com/kamipo/activerecord-mysql-awesome) is required)

```ruby
create_table "articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
  t.string   "title",                    collation: "ascii_bin"
  t.text     "text",       null: false,  collation: "utf8mb4_bin"
  t.datetime "created_at"
  t.datetime "updated_at"
end
```

Charset:

activerecord 5.0.0 and activerecord-mysql-awesome dumps a collation rather than charset because it does not determine the default collation for charset. Specifying a collation for each column would work if it is possible.

See `mysql> show character set;` to find charset / collation pair for your system.

## Execute
```ruby
create_table "authors", force: :cascade do |t|
  t.string "name", null: false
end

create_table "books", force: :cascade do |t|
  t.string  "title",     null: false
  t.integer "author_id", null: false
end

add_index "books", ["author_id"], name: "idx_author_id", using: :btree

execute("ALTER TABLE books ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)") do |c|
  # Execute SQL only if there is no foreign key
  c.raw_connection.query(<<-SQL).each.length.zero?
    SELECT 1 FROM information_schema.key_column_usage
     WHERE TABLE_SCHEMA = 'bookshelf'
       AND CONSTRAINT_NAME = 'fk_author' LIMIT 1
  SQL
end
```

## Diff
```sh
$ ridgepole --diff file1.schema file2.schema
add_column("articles", "author", :text, {:after=>"title"})
rename_column("articles", "text", "desc")

# You can apply to the database the difference:
# $ ridgepole -c config.yml --diff file1.schema file2.schema --with-apply
```

You can also compare databases and files.

```sh
$ ridgepole --diff config.yml file1.schema
remove_column("articles", "author")
```

## Execute SQL using external script

```sh
$ cat test.sh
#!/bin/sh
SQL="$1"
CONFIG_JSON="$2"
echo "$SQL" | mysql -u root my_db

$ ridgepole -c config.yml --apply --external-script ./test.sh
```

## Add extra statement to ALTER

```sh
$ ridgepole -a -c database.yml --alter-extra="LOCK=NONE" --debug
Apply `Schemafile`
...
-- add_column("dept_manager", "to_date2", :date, {:null=>false, :after=>"from_date"})
   (42.2ms)  ALTER TABLE `dept_manager` ADD `to_date2` date NOT NULL AFTER `from_date`,LOCK=NONE
   -> 0.0428s
-- remove_column("dept_manager", "to_date")
   (46.9ms)  ALTER TABLE `dept_manager` DROP `to_date`,LOCK=NONE
   -> 0.0471s
```

## Use ALTER instead of CREATE/DROP INDEX

```sh
$ ridgepole -a -c database.yml --mysql-use-alter --debug
Apply `Schemafile`
...
-- remove_index("dept_manager", {:name=>"emp_no"})
   (19.2ms)  ALTER TABLE `dept_manager` DROP INDEX `emp_no`
   -> 0.0200s
-- add_index("dept_manager", ["emp_no"], {:name=>"emp_no2", :using=>:btree})
   (23.4ms)  ALTER TABLE `dept_manager` ADD  INDEX `emp_no2` USING btree (`emp_no`)
   -> 0.0243s
```

## Relation column type check

```ruby
create_table "employees", force: :cascade do |t|
  t.integer "emp_no", null: false
  t.string  "first_name", limit: 14, null: false
  t.string  "last_name", limit: 16, null: false
end

create_table "dept_manager", force: :cascade do |t|
  t.integer "employee_id"
  t.string  "dept_no", limit: 4, null: false
end
```

```sh
$ ridgepole -a -c database.yml --check-relation-type bigint # default primary key type (e.g. `<5.1`: integer, `>=5.1`: bigint for MySQL)
Apply `Schemafile`
...
[WARNING] Relation column type is different.
              employees.id: bigint
  dept_manager.employee_id: integer
...
```

## Running tests

```sh
docker-compose up -d
bundle install
bundle exec appraisal install
bundle exec appraisal activerecord-5.1 rake
# POSTGRESQL=1 bundle exec appraisal activerecord-5.1 rake
# MYSQL57=1 bundle exec appraisal activerecord-5.1 rake
```

**Notice:** mysql-client/postgresql-client is required.

## Demo

* [asciinema.org/a/9349](https://asciinema.org/a/9349)
* [asciinema.org/a/11788](https://asciinema.org/a/11788)

## Example project

* https://github.com/winebarrel/ridgepole-example
  * https://github.com/winebarrel/ridgepole-example/pull/1
  * https://github.com/winebarrel/ridgepole-example/pull/2

## Similar tools
* [Codenize.tools](http://codenize.tools/)
