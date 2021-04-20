# frozen_string_literal: true

require 'thor'
require 'pathname'

require 'solidus_dev_support/version'

module SolidusDevSupport
  class Extension < Thor
    include Thor::Actions
    PREFIX = 'solidus_'

    default_command :generate

    desc 'generate PATH', 'Generates a new Solidus extension'
    def generate(raw_path = '.')
      self.path = raw_path

      empty_directory path

      adjust_factories_position path

      directory 'app', "#{path}/app"
      directory 'lib', "#{path}/lib"
      directory 'bin', "#{path}/bin"
      directory '.circleci', "#{path}/.circleci"
      directory '.github', "#{path}/.github"

      Dir["#{path}/bin/*"].each do |bin|
        make_executable bin
      end

      template 'CHANGELOG.md', "#{path}/CHANGELOG.md"
      template 'extension.gemspec', "#{path}/#{file_name}.gemspec"
      template 'Gemfile', "#{path}/Gemfile"
      template 'gitignore', "#{path}/.gitignore"
      template 'gem_release.yml.tt', "#{path}/.gem_release.yml"
      template 'LICENSE', "#{path}/LICENSE"
      template 'Rakefile', "#{path}/Rakefile"
      template 'README.md', "#{path}/README.md"
      template 'config/routes.rb', "#{path}/config/routes.rb"
      template 'config/locales/en.yml', "#{path}/config/locales/en.yml"
      template 'rspec', "#{path}/.rspec"
      template 'spec/spec_helper.rb.tt', "#{path}/spec/spec_helper.rb"
      template 'rubocop.yml', "#{path}/.rubocop.yml"
      template 'github_changelog_generator', "#{path}/.github_changelog_generator"
    end

    no_tasks do
      def path=(path)
        path = File.expand_path(path)

        @file_name = Thor::Util.snake_case(File.basename(path))
        @file_name = PREFIX + @file_name unless @file_name.start_with?(PREFIX)

        @class_name = Thor::Util.camel_case file_name

        @root = File.dirname(path)
        @path = File.join(root, file_name)

        @repo = existing_repo || default_repo

        @gemspec = existing_gemspec || default_gemspec
      end

      attr_reader :root, :path, :file_name, :class_name, :gemspec, :repo

      private

      def gemspec_path
        @gemspec_path ||= File.join(path, "#{file_name}.gemspec")
      end

      def default_gemspec
        @default_gemspec ||= Gem::Specification.new(file_name, '0.0.1') do |gem|
          gem.author = git('config user.name', 'TODO: Write your name')
          gem.email = git('config user.email', 'TODO: Write your email address')

          gem.summary = 'TODO: Write a short summary, because RubyGems requires one.'
          gem.description = 'TODO: Write a longer description or delete this line.'
          gem.license = 'BSD-3-Clause'

          gem.metadata['homepage_uri'] = gem.homepage = "https://github.com/#{repo}#readme"
          gem.metadata['changelog_uri'] = "https://github.com/#{repo}/blob/master/CHANGELOG.md"
          gem.metadata['source_code_uri'] = "https://github.com/#{repo}"
        end
      end

      def existing_gemspec
        return unless File.exist?(gemspec_path)

        @existing_gemspec ||= Gem::Specification.load(gemspec_path).tap do |spec|
          spec.author ||= default_gemspec.author
          spec.email ||= default_gemspec.email

          spec.summary ||= default_gemspec.summary
          spec.license ||= default_gemspec.license

          spec.homepage ||= default_gemspec.homepage
          spec.metadata['source_code_uri'] ||= default_gemspec.metadata['source_code_uri']
          spec.metadata['changelog_uri'] ||= default_gemspec.metadata['changelog_uri']
          spec.metadata['source_code_uri'] ||= default_gemspec.metadata['source_code_uri']
        end
      end

      def default_repo
        "solidusio-contrib/#{file_name}"
      end

      def existing_repo
        git('remote get-url origin')&.sub(%r{^.*github\.com.([^/]+)/([^/.]+).*$}, '\1/\2')
      end

      def git(command, default = nil)
        result = `git #{command} 2> /dev/null`.strip
        result.empty? ? default : result
      end

      def make_executable(path)
        path = Pathname(path)
        executable = (path.stat.mode | 0o111)
        path.chmod(executable)
      end

      def adjust_factories_position(path)
        testing_support_folder = File.join(path, "lib/#{file_name}/testing_support/")
        unless File.directory?(testing_support_folder)
          say_status(:create, testing_support_folder)
          FileUtils.mkdir_p(testing_support_folder)
        end

        factories_file_legacy_position = File.join(path, "lib/#{file_name}/factories.rb")
        factories_file_new_position = File.join(path, "lib/#{file_name}/testing_support/factories.rb")

        factories_folder_legacy_position = File.join(path, "lib/#{file_name}/factories")
        factories_folder_new_position = File.join(path, "lib/#{file_name}/testing_support/factories")

        if File.exist?(factories_file_legacy_position) && !File.exist?(factories_file_new_position)
          say_status(:move, "#{factories_file_legacy_position} to #{factories_file_new_position}")
          FileUtils.mv(factories_file_legacy_position, testing_support_folder)
        end
        if Dir.exist?(factories_folder_legacy_position) && !Dir.exist?(factories_folder_new_position) # rubocop:disable Style/GuardClause
          say_status(:move, "#{factories_folder_legacy_position} to #{factories_folder_new_position}")
          FileUtils.mv(factories_folder_legacy_position, testing_support_folder)
        end
      end
    end

    def self.source_root
      "#{__dir__}/templates/extension"
    end
  end
end
