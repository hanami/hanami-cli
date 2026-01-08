This library contains all of the CLI commands for [full-stack Hanami applications](`https://github.com/hanami/hanami`).

**NOTE**: For versions 0.4 and below, there was a general purpose CLI utility library with this name.
That library has since been renamed to [dry-rb/dry-cli](https://github.com/dry-rb/dry-cli).
Please update your Gemfiles accordingly.

## Installation

This library is a dependency of the main `hanami` gem, so installing that is the best way to get and use this gem.

## Usage

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

In order to run all of the tests, you should run `docker compose up` separately, to run a `postgres` server.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hanami/cli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hanami/cli/blob/main/CODE_OF_CONDUCT.md).
