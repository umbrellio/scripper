# Scripper
[![Build Status](https://travis-ci.org/umbrellio/scripper.svg?branch=master)](https://travis-ci.org/umbrellio/scripper)
[![Coverage Status](https://coveralls.io/repos/github/umbrellio/scripper/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/scripper?branch=master)
[![Gem Version](https://badge.fury.io/rb/scripper.svg)](https://badge.fury.io/rb/scripper)

This gem allows you to strip down your Sequel model instances and hashes returned by dataset queries
to simple Ruby structs.

**This gem was only tested against PostgreSQL databases.**

## Why strip models?

It's often convenient to simply call methods on model objects everywhere: controllers, views,
serializers, business logic, and so on. But, by doing so, you're making the whole of your codebase
depend on your database!

This gem is a very basic way to introduce some layer of isolation between your database and the
rest of the codebase. As your application grows, it will be much simpler to transition to more
mature abstractions with such isolation than without it.

The behaviour is more predictable since:
- There are no unexpected database queries (e.x. when loading associations during view rendering)
- There are no leaking database types like `Sequel::Postgres::JSONBHash` (these are converted to hashes automatically)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scripper'
```

And then execute:
```sh
$ bundle
```

It's recommended to "wrap" this gem into a separate module:
```ruby
# lib/stripper.rb

Stripper = Scripper::Sequel
```

## Usage

It's very simple! Scripper works both with instances of Sequel::Model and hashes returned when
using naked models or datasets.

```ruby
# with models
user = User.first
Stripper.strip(user) # => #<struct  id=2, email="cow@cow.cow", password_hash="...">
user.email # => "cow@cow.cow"

# with datasets
user = DB[:users].first # or: User.naked.first
Stripper.strip(user) # => #<struct  id=2, email="cow@cow.cow", password_hash="...">
user.email # => "cow@cow.cow"
```

### Loading associations

If you'd like to also use associations on your struct (works only with models):

```ruby
user = User.first
Stripper.strip(user, with_associations: %w[cookies])
# => #<struct  id=2, ..., cookies=[#<struct  ...>, #<struct  ...>, #<struct  ...>]>
```

Beware that this will load _all_ cookies associated with your user! If you want to impose some
filtering conditions, you can do that:

```ruby
user = User.first
Stripper.strip(
  user,
  with_associations: { cookies: -> (ds) { ds.where(active: true).limit(10) } },
)
```

This will only load no more than 10 active cookies.

### Providing extra attributes

Sometimes it's useful to provide some context beyond associations and model/dataset attributes.

In the example below, we're providing information about user's payment sum, not only user's fields.

```ruby
# with a model
user = User
  .left_join(:payments)
  .select_all(:users)
  .select_append(
    Sequel.function(:sum, Sequel[:payments][:amount]).as(:payment_sum),
  )
  .group(Sequel[:users][:id])
  .first

Stripper.strip(user, with_attributes: { payment_sum: user[:payment_sum] })
# => #<struct  id=2, ..., payment_sum=418.0>

# with a dataset, it's nearly identical
user = DB[:users]
  .left_join(:payments)
  .select_all(:users)
  .select_append(
    Sequel.function(:sum, Sequel[:payments][:amount]).as(:payment_sum),
  )
  .group(Sequel[:users][:id])
  .first

Stripper.strip(user, with_attributes: { payment_sum: user[:payment_sum] })
# => #<struct  id=2, ..., payment_sum=418.0>
```

## Default value conversions

`Sequel::Postgres::JSONHashBase` (`JSONBHash`, `JSONHash`, ...) => `Hash`

`Sequel::Postgres::JSONArrayBase` (`JSONBArray`, `JSONArray`, ...) => `Array`

`Sequel::Postgres::PGArray` => `Array`

`BigDecimal` => `Float`

Currently, these are not extensible.

## Roadmap

It would be lovely to:
- Make value conversions extensible
- Support ActiveRecord
- Test the gem on other databases

Your contributions and feedback are very welcome!

## Development

To run tests, you need to first create a PostgreSQL database, and then set a `DB_URL` variable.

Example:
```sh
DB_URL=postgres://localhost/scripper_test bundle exec rspec
```

If you want to enable Sequel's database access logging during spec runs, use `LOG_DB=1`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbrellio/scripper.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Authors
Created by [Alexander Komarov](https://github.com/akxcv).

<a href="https://github.com/umbrellio/">
  <img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
