# solidus_dev_support


[![CircleCI](https://circleci.com/gh/solidusio/solidus_dev_support.svg?style=shield)](https://circleci.com/gh/solidusio/solidus_dev_support)
[![codecov](https://codecov.io/gh/solidusio/solidus_dev_support/branch/master/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_dev_support)

This gem contains common development functionality for Solidus extensions.

If you're looking for runtime tools instead, look at
[solidus_support](https://github.com/solidusio/solidus_support).

## Installation

Add this gem as a development dependency of your extension:

```ruby
spec.add_development_dependency 'solidus_dev_support'
```

And then execute:

```console
$ bundle
```

## Usage

### Extension generator

This gem provides a generator for Solidus extensions. To use it, simply run:

```console
$ solidus extension my_awesome_extension
```

This will generate the basic extension structure, already configured to use all the shiny helpers
in solidus_dev_support.

#### Updating existing extensions

If you have an existing extension and want to update it to use the latest standards from this gem,
you can run the following in the extension's directory:

```console
$ bundle exec solidus extension .
```

In case of conflicting files, you will be prompted for an action. You can overwrite the files with
the new version, keep the current version or view the diff and only apply the adjustments that make
sense to you.

### Sandbox app

When developing an extension you will surely need to try it out within a Rails app with Solidus
installed. Using solidus_dev_support your extension will have a `bin/rails-sandbox` executable that will
operate on a _sandbox_ app (creating it if necessary).

The path for the sandbox app is `./sandbox` and `bin/rails-sandbox` will forward any Rails command
to `sandbox/bin/rails`.

Example:

```bash
$ bin/rails-sandbox server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

#### Rebuilding the sandbox app

To rebuild the sandbox app just remove the `./sandbox` folder or run `bin/sandbox`.
You can control the DB adapter and Solidus version used with the sandbox by providing
the `DB` and `SOLIDUS_BRANCH` env variables.

```bash
DB=[postgres|mysql|sqlite] SOLIDUS_BRANCH=<BRANCH-NAME> bin/sandbox
```

By default we use sqlite3 and the master branch.

### Rails generators

Your extension will have a `bin/rails-engine` executable that you can use for generating models, migrations
etc. It's the same as the default `rails` command in Rails engines.

Example:

```bash
$ bin/rails-engine generate migration AddStoreIdToProducts
```

### The `bin/rails` shortcut

For convenience a `bin/rails` executable is also provided that will run everything but generators on the sandbox application. Generators will instead be processed in the context of the extension.


### RSpec helpers

This gem provides some useful helpers for RSpec to setup an extension's test environment easily.

Add this to your extension's `spec/spec_helper.rb`:

```ruby
require 'solidus_dev_support/rspec/feature_helper'
```

This helper loads configuration needed to run extension feature specs correctly, setting up Capybara
and configuring a Rails test application to precompile assets before the first feature spec.

`feature_helper` builds on top of `rails_helper`, which you can also use a standalone helper if you
want:

```ruby
require 'solidus_dev_support/rspec/rails_helper'
```

This will include the Rails and Solidus-related RSpec configuration, such as authorization helpers,
Solidus factories, URL helpers, and other helpers to easily work with Solidus.

`rails_helper`, in turn, builds on top of `spec_helper`, which is responsible for setting up a
basic RSpec environment:

```ruby
require 'solidus_dev_support/rspec/spec_helper'
```

### Code coverage

The gem also includes a SimpleCov configuration that will send your test coverage information
directly to Codecov.io. Simply add this at the top of your `spec/spec_helper.rb`:

```ruby
require 'solidus_dev_support/rspec/coverage'
```

**Note: Make sure to add this at the VERY TOP of your spec_helper, otherwise you'll get skewed
coverage reports!**

If your extension is in a public repo and being tested on Travis or CircleCI, there's nothing else
you need to do! If your setup is more complex, look at the
[SimpleCov](https://github.com/colszowka/simplecov)
and [codecov-ruby](https://github.com/codecov/codecov-ruby) docs.

### RuboCop configuration

solidus_dev_support includes a default [RuboCop](https://github.com/rubocop-hq/rubocop)
configuration for Solidus extensions. Currently, this is based on
[Relaxed Ruby Style](https://relaxed.ruby.style) with a few customizations, but in the future we
plan to provide custom cops to ensure your extension follows established Solidus best practices.

We strongly recommend including the RuboCop configuration in your extension. All you have to do is
add this to your `.rubocop.yml`:

```yaml
require:
  - solidus_dev_support/rubocop
```

You can now run RuboCop with:

```console
$ bundle exec rubocop
```

### Changelog generator

Generating a changelog for your extension is possible by running this command:

```console
$ CHANGELOG_GITHUB_TOKEN="«your-40-digit-github-token»" bundle exec github_changelog_generator github_username/github_project
```

This generates a `CHANGELOG.md`, with pretty Markdown formatting.

For further instructions please read the [GitHub Changelog Generator documentation](https://github.com/github-changelog-generator/github-changelog-generator#usage).

### Release management

By installing solidus_dev_support, you also get
[`gem release`](https://github.com/svenfuchs/gem-release), which you can use to automatically manage
releases for your gem.

For instance, you can run the following to release a new minor version:

```console
$ gem bump -v minor -r
```

The above command will:

* bump the gem version to the next minor (you can also use `patch`, `major` or a specific version
  number);
* commit the change and push it to `origin/master`;
* create a Git tag;
* push the tag to the `origin` remote;
* release the new version on RubyGems.

You can refer to
[`gem release`'s documentation](https://github.com/svenfuchs/gem-release/blob/master/README.md) for
further configuration and usage instructions.

### Rake tasks

To install extension-related Rake tasks, add this to your `Rakefile`:

```rb
require 'solidus_dev_support/rake_tasks'
SolidusDevSupport::RakeTasks.install

task default: 'extension:specs'
```

(If your extension used the legacy extension Rakefile, then you should completely replace its
contents with the block above.)

This will provide the following tasks:

- `extension:test_app`, which generates a dummy app for your extension
- `extension:specs` (default), which runs the specs for your extension

If your extension requires the `test_app` to be always recreated you can do so by running:

```rb
bin/rake extension:test_app extension:specs
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bin/rake install`.

To release a new version:

1. update the version number in `version.rb`
2. update the changelog with `bin/rake changelog`
3. commit the changes using `Bump SolidusDevSupport to 1.2.3` as the message
3. run `bin/rake release`

The last command will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solidusio/solidus_dev_support.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
