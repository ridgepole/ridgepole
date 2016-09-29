# Ridgepole

Ridgepole is a tool to manage DB schema.

It defines DB schema using [Rails DSL](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps), and updates DB schema according to DSL.
(like Chef/Puppet)

[![Gem Version](https://badge.fury.io/rb/ridgepole.svg)](http://badge.fury.io/rb/ridgepole)
[![Build Status](https://travis-ci.org/winebarrel/ridgepole.svg?branch=master)](https://travis-ci.org/winebarrel/ridgepole)
[![Coverage Status](https://coveralls.io/repos/winebarrel/ridgepole/badge.svg?branch=master)](https://coveralls.io/r/winebarrel/ridgepole?branch=master)

**Important**

Please don't use the following nameless fk:

```ruby 
add_foreign_key :articles, :authors # without `name:`
```

**It is highly recommended to give a name to the fk explicitly.**

![](https://cdn.pbrd.co/images/8Ymz6nU5x.gif)

**Notice**

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

## Installation

Add this line to your application's Gemfile:

    gem 'ridgepole'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ridgepole

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

$ ridgepole -c config.yml --export -o Schemafile # or `ridgepole -c '{adapter: mysql2, database: blog}' ...`
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

**Notice:** **It is highly recommended to give a name to the fk explicitly.**

Please pass `--dump-with-default-fk-name` option if you want to use the nameless index.

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
  c.raw_connection.query("SELECT 1 FROM information_schema.key_column_usage WHERE TABLE_SCHEMA = 'bookshelf' AND CONSTRAINT_NAME = 'fk_author' LIMIT 1").each.length.zero?
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

### Reverse diff
```sh
$ cat file1.schema
create_table "articles", force: :cascade do |t|
  t.string   "title"
  t.text     "text"
  t.datetime "created_at"
  t.datetime "updated_at"
end

$ cat file2.schema
create_table "articles", force: :cascade do |t|
  t.string   "title"
  t.text     "desc", renamed_from: "text"
  t.text     "author"
  t.datetime "created_at"
  t.datetime "updated_at"
end

$ ridgepole --diff file1.schema file2.schema
add_column("articles", "author", :text, {:after=>"title"})
rename_column("articles", "text", "desc")

$ ridgepole --diff file1.schema file2.schema --reverse
rename_column("articles", "desc", "text")
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

## Running tests

```sh
docker-compose up -d
bundle install
bundle exec appraisal install
bundle exec appraisal activerecord-4.2 rake
# ENABLE_MYSQL_AWESOME=1 bundle exec appraisal activerecord-4.2 rake
# POSTGRESQL=1 bundle exec appraisal activerecord-4.2 rake
```

**Notice:** mysql-client/postgresql-client is required.

### on OS X (docker-machine & VirtualBox)

Port forwarding is required.

```sh
VBoxManage controlvm default natpf1 "mysql,tcp,127.0.0.1,3306,,3306"
VBoxManage controlvm default natpf1 "psql,tcp,127.0.0.1,5432,,5432"
```

## Demo

* [asciinema.org/a/9349](https://asciinema.org/a/9349)
* [asciinema.org/a/11788](https://asciinema.org/a/11788)

## Example project

* https://github.com/winebarrel/ridgepole-example
  * https://github.com/winebarrel/ridgepole-example/pull/1
  * https://github.com/winebarrel/ridgepole-example/pull/2

## Similar tools
* [Codenize.tools](http://codenize.tools/)
