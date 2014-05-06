# Ridgepole

Ridgepole is a tool to DB schema.
It defines DB schema using [Rails DSL](http://guides.rubyonrails.org/migrations.html#types-of-schema-dumps), and updates DB schema according to DSL.

## Installation

Add this line to your application's Gemfile:

    gem 'ridgepole'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ridgepole

## Usage

```sh
ridgepole --export -o Schemafile
vi Schemafile
ridgepole --apply --dry-run
ridgepole --apply
```
