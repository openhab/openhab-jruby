# @title Contributing

# Contributing

Contributions, issues and pull requests are welcome.  Please visit the [GitHub home](https://github.com/openhab/openhab-jruby) for this project.

## License

This code is under the [Eclipse v2 license](https://www.eclipse.org/legal/epl-2.0/)

## Source

JRuby Scripting openHAB is hosted on [GitHub](https://github.com/openhab/openhab-jruby).

## Development Environment Setup

The development process has been tested on MacOS, and Ubuntu. Other operating systems may work.

1. Install Ruby 2.6.8 and JRuby 9.3.8.0 (or later)
1. Fork [the repo](https://github.com/openhab/openhab-jruby) and clone it
1. Install [bundler](https://bundler.io/)
1. Run `bundler install` from inside of the repo directory
1. To avoid conflicts, the openHAB development instance can use custom ports by defining these environment variables:
   - `OPENHAB_HTTP_PORT`
   - `OPENHAB_HTTPS_PORT`
   - `OPENHAB_SSH_PORT`
   - `OPENHAB_LSP_PORT`
1. Run `bundle exec rake openhab:setup` from inside of the repo directory.  This will download a copy of openHAB local in your development environment, start it and prepare it for JRuby openHAB Scripting Development
1. Install [pre-commit](https://pre-commit.com) and then run `pre-commit install` if you would like to install a git pre-commit hook to automatically run rubocop.

## Code Documentation

Code documentation is written in [Yard](https://yardoc.org/) and the current documentation for this project is available on [GitHub pages](https://openhab.github.io/openhab-jruby/).

## Development Process

1. Create a branch for your contribution.
1. Write your tests the project uses [Behavior Driven Development](https://en.wikipedia.org/wiki/Behavior-driven_development) with [RSpec](https://rspec.info/). The spec directory has many examples.  Feel free ask in your PR if you need help.
1. Write your code.
1. Verify your tests now pass by running `bin/rspec spec/<your spec file>_spec.rb`. This requires JRuby.
1. Update the documentation, run `bin/yardoc` to view the rendered documentation locally
1. Lint your code with `bundle exec rake lint:rubocop` and ensure you have not created any [Rubocop](https://github.com/rubocop-hq/rubocop) violations.
1. Submit your PR(s)!

If you get stuck or need help along the way, please open an issue.
