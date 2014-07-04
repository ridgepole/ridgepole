# Ridgepole

Ridgepole is a tool to DB schema.

It defines DB schema using [Rails DSL](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps), and updates DB schema according to DSL.
(like Chef/Puppet)

[![Gem Version](https://badge.fury.io/rb/ridgepole.png)](http://badge.fury.io/rb/ridgepole)
[![Build Status](https://drone.io/github.com/winebarrel/ridgepole/status.png)](https://drone.io/github.com/winebarrel/ridgepole/latest)

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
    -a, --apply
    -m, --merge
    -f, --file FILE
        --dry-run
    -e, --export
        --split
        --split-with-dir
    -d, --diff DSL1 DSL2
        --reverse
        --with-apply
    -o, --output FILE
    -t, --tables TABLES
        --ignore-tables TABLES
        --disable-mysql-unsigned
        --log-file LOG_FILE
        --verbose
        --debug
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
create_table "articles", force: true do |t|
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
 create_table "articles", force: true do |t|
   t.string   "title"
   t.text     "text"
+  t.text     "author"
   t.datetime "created_at"
   t.datetime "updated_at"
 end

$ ridgepole -c config.yml --apply --dry-run
Apply `Schemafile` (dry-run)
add_column("articles", "author", :text, {:after=>"text"})

$ ridgepole -c config.yml --apply
Apply `Schemafile`
-- add_column("articles", "author", :text, {:after=>"text"})
   -> 0.0202s
```

## Rename
```sh
create_table "articles", force: true do |t|
  t.string   "title"
  t.text     "desc", rename_from: "text"
  t.text     "author"
  t.datetime "created_at"
  t.datetime "updated_at"
end

create_table "user_comments", force: true, rename_from: "comments" do |t|
  t.string   "commenter"
  t.text     "body"
  t.integer  "article_id"
  t.datetime "created_at"
  t.datetime "updated_at"
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
create_table "articles", force: true do |t|
  t.string   "title"
  t.text     "text"
  t.datetime "created_at"
  t.datetime "updated_at"
end

$ cat file2.schema
create_table "articles", force: true do |t|
  t.string   "title"
  t.text     "desc", rename_from: "text"
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

## Demo

* [asciinema.org/a/9349](https://asciinema.org/a/9349)

## Example project

* https://github.com/winebarrel/ridgepole-example
  * https://github.com/winebarrel/ridgepole-example/pull/1
  * https://github.com/winebarrel/ridgepole-example/pull/2
