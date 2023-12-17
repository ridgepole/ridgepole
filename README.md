# Ridgepole

Ridgepole is a tool to manage DB schema.

It defines DB schema using [Rails DSL](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps), and updates DB schema according to DSL.
(like Chef/Puppet)

[![Gem Version](https://badge.fury.io/rb/ridgepole.svg)](https://badge.fury.io/rb/ridgepole)
[![Build Status](https://github.com/ridgepole/ridgepole/workflows/test/badge.svg?branch=1.2)](https://github.com/ridgepole/ridgepole/actions)
[![Coverage Status](https://coveralls.io/repos/github/ridgepole/ridgepole/badge.svg?branch=1.2)](https://coveralls.io/github/ridgepole/ridgepole?branch=1.2)

> [!note]
> * ridgepole v2.0.0
>   * Support Trilogy (cf. https://github.com/ridgepole/ridgepole/pull/447)
>   * Support Rails 7.1 (cf. https://github.com/ridgepole/ridgepole/pull/441)
>   * Drop support AcriveRecord 6.0 (cf. https://github.com/ridgepole/ridgepole/pull/440)
> * Drop support ActiveRecord 5.x in ridgepole v1.2.0.
> * Partitioning is no longer supported in ridgepole v1.1.0.
> * ActiveRecord 7.x has some incompatible changes. If you get unintended differences in `datetime` columns consider changing `precision`:
>   * Add `precision: nil` for columns that previously had no `precision` specified (cf. https://github.com/ridgepole/ridgepole/issues/381)
>   * Remove `precision: 6` from columns that previously had `precision: 6` specified explicitly (cf. https://github.com/ridgepole/ridgepole/issues/406)
> * For ActiveRecord 7.x series, please use AcriveRecord 7.0.2 or higher / Ridgepole 1.0.3 or higher.
>   * cf. https://github.com/ridgepole/ridgepole/pull/380
> * ActiveRecord 6.1 is supported in ridgepole v0.9, but the ActiveRecord dump has been changed, so there is a difference between ActiveRecord 5.x/6.0 format.
>   * **If you use ActiveRecord 6.1, please modify Schemafile format**.
>   * cf. https://github.com/ridgepole/ridgepole/pull/323
> * `DROP TABLE` is skipped by default in v1.0 and later versions.
>   * If you want to `DROP TABLE`, please pass `--drop-table`.
>   * cf. https://github.com/ridgepole/ridgepole/pull/363
> * In Rails 7.0, the output of dumper is different from Rails 6.
>   * cf. https://github.com/rails/rails/issues/43909
>   * cf. https://github.com/rails/rails/commit/c2a6f618d22cca4d9b7be7fa7652e7aac509350c#diff-55f41513f027a3d219629f475f03c2d1105ca55c5093d691e1b3dc4710c6cc0b
> * SQLite does not support.

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
    -s, --spec-name SPEC_NAME
    -a, --apply
    -m, --merge
    -f, --file SCHEMAFILE
        --dry-run
        --table-options OPTIONS
        --table-hash-options OPTIONS
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
        --dump-without-table-options
        --dump-with-default-fk-name
        --index-removed-drop-column
        --drop-table
        --mysql-change-table-options
        --mysql-change-table-comment
        --check-relation-type DEF_PK
        --ignore-table-comment
        --skip-column-comment-change
        --create-table-with-index
        --allow-pk-change
        --mysql-dump-auto-increment
    -r, --require LIBS
        --log-file LOG_FILE
        --verbose
        --debug
        --[no-]color
    -v, --version
    -h, --help
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
  t.bigint "id"
  t.bigint "parent_id"
end

add_index "child", ["parent_id"], name: "par_ind", using: :btree

add_foreign_key "child", "parent", name: "child_ibfk_1"
```

## Ignore Column/Index/FK

```ruby
create_table "articles", force: :cascade do |t|
  t.string   "title", ignore: true # All changes are ignored
  t.text     "desc", renamed_from: "text"
  t.text     "author"
  t.datetime "created_at"
  t.datetime "updated_at"
end
```

## Collation/Charset

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

## Generated Column (MySQL)

There should be NO extra white spaces in the expression (such as after comma).
Quotes in expression may cause the operations failure with MySQL 8.0.

```ruby
create_table "users", force: :cascade do |t|
  t.string   "last_name"
  t.string   "first_name"
  t.virtual  "full_name", type: :string, as: "concat(`last_name`,' ',`first_name`)", stored: true
end
```

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
  c.raw_connection.query(<<-SQL).each.size.zero?
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
$ ridgepole -a -c database.yml --check-relation-type bigint # default primary key type (e.g. bigint for MySQL)
Apply `Schemafile`
...
[WARNING] Relation column type is different.
              employees.id: bigint
  dept_manager.employee_id: integer
...
```

## Run tests


```sh
docker compose up -d
bundle install
bundle exec appraisal install
bundle exec appraisal activerecord-7.0 rake
# POSTGRESQL=1 bundle exec appraisal activerecord-7.0 rake
# MYSQL80=1 bundle exec appraisal activerecord-7.0 rake
```

**Notice:** Ruby 2.6 or above/mysql-client/postgresql-client is required.

## Demo

* [asciinema.org/a/9349](https://asciinema.org/a/9349)
* [asciinema.org/a/11788](https://asciinema.org/a/11788)

## Example project

* https://github.com/winebarrel/ridgepole-example
  * https://github.com/winebarrel/ridgepole-example/pull/1
  * https://github.com/winebarrel/ridgepole-example/pull/2
