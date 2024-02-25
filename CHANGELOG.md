# Changelog

## 2.0

### 2.0.2 (2024/02/25)

- Fix bug that cannot include single quote in table comment [pull#467](https://github.com/ridgepole/ridgepole/pull/467)

### 2.0.1 (2023/11/22)

- Fix renamed_from bug [pull#453](https://github.com/ridgepole/ridgepole/pull/453)

### 2.0.1 (2023/11/22)

- Fix renamed_from bug [pull#453](https://github.com/ridgepole/ridgepole/pull/453)

### 2.0.0 (2023/11/10)

- Bump up version.

### 2.0.0.beta2 (2023/10/26)

- Support Rails 7.1 [pull#447](https://github.com/ridgepole/ridgepole/pull/447)
- Drop Rails 6.0 support [pull#440](https://github.com/ridgepole/ridgepole/pull/440)

### 2.0.0.beta (2023/10/22)

- Support Rails 7.1 [pull#441](https://github.com/ridgepole/ridgepole/pull/441)
- Drop Rails 6.0 support [pull#440](https://github.com/ridgepole/ridgepole/pull/440)

## 1.2

### 1.2.1 (2023/07/29)

- Support `t.enum` [pull#405](https://github.com/ridgepole/ridgepole/pull/405)
- Fix timestamps with index behavior [pull#428](https://github.com/ridgepole/ridgepole/pull/428)
- Fix broken `DEFAULT CURRENT_TIMESTAMP` spec [pull#420](https://github.com/ridgepole/ridgepole/pull/420)
- Add Ruby 3.2 to CI matrix [pull#419](https://github.com/ridgepole/ridgepole/pull/419)

### 1.2.0 (2022/09/24)

- Updated supported column types [pull#399](https://github.com/ridgepole/ridgepole/pull/399) [pull#400](https://github.com/ridgepole/ridgepole/pull/400)
- Support check constraint [pull#393](https://github.com/ridgepole/ridgepole/pull/393) [pull#397](https://github.com/ridgepole/ridgepole/pull/397)
- Drop suport Rails 5.x [pull#395](https://github.com/ridgepole/ridgepole/pull/395)

## 1.1

### 1.1.0 (2022/06/18)

- Revert partitioning support [pull#392](https://github.com/ridgepole/ridgepole/pull/392)

## 1.0

### 1.0.7 (2022/06/09)

- Normalize list partition values for PostgreSQL [pull#389](https://github.com/ridgepole/ridgepole/pull/389)

### 1.0.6 (2022/06/06)

- Support Hash partition for PostgreSQL [pull#387](https://github.com/ridgepole/ridgepole/pull/387)

### 1.0.5 (2022/06/05)

- Support DEFAULT partition for PostgreSQL [pull#386](https://github.com/ridgepole/ridgepole/pull/386)

### 1.0.4 (2022/03/28)

- Add warning for generated column [pull#382](https://github.com/ridgepole/ridgepole/pull/382)

### 1.0.3 (2022/02/12)

- Support Rails 7.0.2 [pull#380](https://github.com/ridgepole/ridgepole/pull/380)

### 1.0.2 (2022/02/06)

- Add support for partitioning ([pull#374](https://github.com/ridgepole/ridgepole/pull/374))
- Suppress warning of table option differences ([pull#378](https://github.com/ridgepole/ridgepole/pull/378))

### 1.0.1 (2022/01/15)

- Fix code for RuboCop 1.24.1
- Fix PostgreSQL spec for Rails 7.0
- Update ERBh gem (for development)

### 1.0.0 (2021/12/19)

- Support Rails 7.0
- `--skip-drop-table` by default ([pull#363](https://github.com/ridgepole/ridgepole/pull/363))

## 0.9

### 0.9.6

- Fix malformed error ([pull#362](https://github.com/ridgepole/ridgepole/pull/362))

### 0.9.5

- Call `super` in `disable_table_options.rb` ([pull#357](https://github.com/ridgepole/ridgepole/pull/357))

### 0.9.4

- Fix `--alter-extra` option for unique index ([pull#356](https://github.com/ridgepole/ridgepole/pull/356))

### 0.9.3

- Fix `limit` option for `t.integer` ([pull#354](https://github.com/ridgepole/ridgepole/pull/354))

### 0.9.2

- Support `t.column index option` ([pull#353](https://github.com/ridgepole/ridgepole/pull/353))

### 0.9.1

- Support `t.foreign_key` ([pull#348](https://github.com/ridgepole/ridgepole/pull/348))

### 0.9.0

- Remove `--mysql-use-alter` option ([pull#330](https://github.com/ridgepole/ridgepole/pull/330))
- Add `--table-hash-options` option ([pull#331](https://github.com/ridgepole/ridgepole/pull/331))
- Support Rails 6.1 ([pull#323](https://github.com/ridgepole/ridgepole/pull/323))
- Disable Rails 5.0 support ([pull#335](https://github.com/ridgepole/ridgepole/pull/335))
- Fix PK AUTO_INCREMENT change bug ([pull#334](https://github.com/ridgepole/ridgepole/pull/334))

## 0.8

### 0.8.13

- Support `serial` and `bigserial` column types ([pull#321](https://github.com/ridgepole/ridgepole/pull/321))

### 0.8.12

- Pluralize column specified by `references` ([pull#317](https://github.com/ridgepole/ridgepole/pull/317))

### 0.8.11

- Fix FK index check support multiple PK ([pull#315](https://github.com/ridgepole/ridgepole/pull/315))
- Support t.reference() foreign_key option ([pull#316](https://github.com/ridgepole/ridgepole/pull/316))

### 0.8.10

- Raise an error if an InnoDB column has a foreign key but no index ([pull#310](https://github.com/ridgepole/ridgepole/pull/310))

### 0.8.9

- Fix unexpected differences on text types and blob types on Rails 6 ([pull#306](https://github.com/ridgepole/ridgepole/pull/306))
- Fix unexpected warning when a foreign key is added on the primary key ([pull#307](https://github.com/ridgepole/ridgepole/pull/307))

### 0.8.8

- Fix keyword arguments warnings in Ruby 2.7 ([pull#303](https://github.com/ridgepole/ridgepole/pull/303))

### 0.8.7

- Support `require_relative` ([pull#298](https://github.com/ridgepole/ridgepole/pull/298))

### 0.8.6

- Support multiple databases feature ([pull#297](https://github.com/ridgepole/ridgepole/pull/297))

### 0.8.5

- Improve warning message on table options ([pull#291](https://github.com/ridgepole/ridgepole/pull/291))

### 0.8.4

- Display a warning if an InnoDB table doesn't have any indexes on a column where it has a foreign key ([pull#290](https://github.com/ridgepole/ridgepole/pull/290))

### 0.8.3

- Fix "topological sort failed" error ([pull#287](https://github.com/ridgepole/ridgepole/pull/287))

### 0.8.2

- Support `postgres://` schema ([pull#285](https://github.com/ridgepole/ridgepole/pull/285))

### 0.8.1

- Drop tables in an order considering foreign key constraints ([pull#284](https://github.com/ridgepole/ridgepole/pull/284))

### 0.8.0

- Support Rails 6.0

## 0.7

### 0.7.8

- Fix for `add_foreign_key(..., column: ,,,)` ([pull#278](https://github.com/ridgepole/ridgepole/pull/278))

### 0.7.7

- Support URI query string ([pull#273](https://github.com/ridgepole/ridgepole/pull/273))

### 0.7.6

- Fix database url check ([pull#266](https://github.com/ridgepole/ridgepole/pull/266))
- Add ignore option ([pull#267](https://github.com/ridgepole/ridgepole/pull/267))

### 0.7.5

- Fix polymorphic options ([pull#263](https://github.com/ridgepole/ridgepole/pull/263))
- Fix `--mysql-use-alter` option ([pull#246](https://github.com/ridgepole/ridgepole/pull/264))
- Fix Database URI parsing ([pull#265](https://github.com/ridgepole/ridgepole/pull/265))

### 0.7.4

- Fix `add_foreign_key` options ([issue#250](https://github.com/ridgepole/ridgepole/issues/250))

### 0.7.3

- Add `--mysql-change-table-comment option` ([pull#166](https://github.com/ridgepole/ridgepole/pull/166))
- Refactoring with RuboCop
- Support primary key adding/dropping ([issue#246](https://github.com/ridgepole/ridgepole/issues/246))

### 0.7.2

- Support Rails 5.2

### 0.7.1

- Remove `--reverse` option
- Add `--allow-pk-change` option
- Add `--create-table-with-index` option
- Add `--mysql-dump-auto-increment` option (`rails >= 5.1`)

### 0.7.0

- Remove Rails 4.x support
- Add Rails 5.1 support
- Remove `--enable-mysql-awesome` option
- Add `--skip-drop-table` option
- Support foreign key without name
- Support MySQL JSON Type and Generated Columns
- Add `--mysql-change-table-options` option
- Pass config from env
- Fix change fk order
- Add `--check-relation-type` option
- Add `--skip-column-comment-change` option
- Add `--default-bigint-limit` option
- Add `--ignore-table-comment` option

## 0.6

### 0.6.6

- Use `t.column` for migration ([pull#114](https://github.com/ridgepole/ridgepole/pull/114))
- Support DATABASE_URL format ([pull#118](https://github.com/ridgepole/ridgepole/pull/118))
- Add Ruby2.4 CI ([pull#119](https://github.com/ridgepole/ridgepole/pull/119))

### 0.6.5

- Fix rails version `'>= 4.2', '< 6'`
- Support new types ([pull#84](https://github.com/ridgepole/ridgepole/pull/84))
- Support `default: -> { ... }` ([pull#85](https://github.com/ridgepole/ridgepole/pull/85))
- Support DDL Comment (Rails5 only)
- Output schema diff when pass `--verbose`
- Support composite primary key (Rails5 only / [pull#97](https://github.com/ridgepole/ridgepole/pull/97))

### 0.6.4

- Execute sql using external script ([pull#56](https://github.com/ridgepole/ridgepole/pull/56))
- Add `--mysql-use-alter` option
- Add `--alter-extra` option
- Add `--dump-with-default-fk-name` option
- Support `t.index` ([pull#64](https://github.com/ridgepole/ridgepole/pull/64))
- Remove migration_comments
- Fix foreign key apply order

### 0.6.3

- Fix `default` option ([pull#48](https://github.com/ridgepole/ridgepole/pull/48))
- Add `--enable-migration-comments` option ([pull#50](https://github.com/ridgepole/ridgepole/pull/50))
- Disable `rename_table_indexes`

### 0.6.1

- Support [PostgreSQL columns](https://github.com/winebarrel/rails/blob/v4.2.1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L79)

### 0.6.0

- Fix rails version `~> 4.2.1`
- Disable following libraries support:
  - activerecord-mysql-unsigned
  - migration_comments
  - foreigner
- Disable sqlite support
- Add PostgreSQL test
- Remove `--mysql-awesome-unsigned-pk` option

## 0.5

### 0.5.2

- Add `--enable-mysql-awesome` option ([activerecord-mysql-awesome](https://github.com/kamipo/activerecord-mysql-awesome) is required `>= 0.0.3`)
- It is not possible to enable both `--enable-mysql-awesome` and `--enable-migration-comments`, `--enable-mysql-awesome` and `--enable-mysql-unsigned`, `--enable-mysql-awesome` and `--enable-mysql-pkdump`
- Fix foreigner version `<= 1.7.1`

### 0.5.1

- Add `--enable-migration-comments` option ([migration_comments](https://github.com/pinnymz/migration_comments) is required)
- Fix rails version `< 4.2.0`

### 0.5.0

- Fix `activerecord-mysql-unsigned` version: `~> 0.3.1`

## 0.4

### 0.4.12

- Fix `activerecord-mysql-unsigned` version: `~> 0.2.0`

### 0.4.11

- Add `--enable-mysql-pkdump` option.

### 0.4.8

- `activerecord-mysql-unsigned` is now optional. Please pass `--enable-mysql-unsigned` after you install [activerecord-mysql-unsigned](https://github.com/waka/activerecord-mysql-unsigned) if you want to use.
- Please pass `--enable-foreigner` after you install [foreigner](https://github.com/matthuhiggins/foreigner) if you want to use the foreign key.
