# frozen_string_literal: true

require_relative 'lib/solidus_dev_support/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_dev_support'
  spec.version = SolidusDevSupport::VERSION
  spec.authors = ['Alessandro Desantis']
  spec.email = ['alessandrodesantis@nebulab.it']

  spec.summary = 'Development tools for Solidus extensions.'
  spec.homepage = 'https://github.com/solidusio/solidus_dev_support'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio/solidus_dev_support'
  spec.metadata['changelog_uri'] = 'https://github.com/solidusio/solidus_dev_support/blob/master/CHANGELOG.md'

  spec.required_ruby_version = '>= 2.6'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'capybara', '~> 3.29'
  spec.add_dependency 'capybara-screenshot', '~> 1.0'
  spec.add_dependency 'codecov', '~> 0.2'
  spec.add_dependency 'database_cleaner', '~> 1.7'
  spec.add_dependency 'factory_bot', '~> 4.8'
  spec.add_dependency 'factory_bot_rails'
  spec.add_dependency 'ffaker', '~> 2.13'
  spec.add_dependency 'gem-release', '~> 2.1'
  spec.add_dependency 'github_changelog_generator', '~> 1.15'
  spec.add_dependency 'puma', '~> 4.3'
  spec.add_dependency 'rspec_junit_formatter'
  spec.add_dependency 'rspec-rails', '~> 4.0.0.beta3'
  spec.add_dependency 'rubocop', '~> 1.0'
  spec.add_dependency 'rubocop-performance', '~> 1.5'
  spec.add_dependency 'rubocop-rails', '~> 2.3'
  spec.add_dependency 'rubocop-rspec', '~> 2.0'
  spec.add_dependency 'solidus_core', ['>= 2.0', '< 4']
  spec.add_dependency 'webdrivers', '~> 4.4'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
