# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'spec_helper'
require 'spree/core/version'

RSpec.describe 'Create extension' do
  include FileUtils

  let(:gem_root) { File.expand_path('../..', __dir__) }
  let(:solidus_cmd) { "#{gem_root}/exe/solidus" }
  let(:extension_name) { 'test_extension' }
  let(:gemspec_name) { "solidus_#{extension_name}.gemspec" }
  let(:tmp_path) { Pathname.new(gem_root).join('tmp') }
  let(:install_path) { tmp_path.join("solidus_#{extension_name}") }
  let(:command_failed_error) { Class.new(StandardError) }

  before do
    rm_rf(install_path)
    mkdir_p(tmp_path)
  end

  def step(method_name)
    puts "Step #{method_name}"
    send method_name
  end

  it 'checks the create extension process' do
    step :check_solidus_cmd
    step :check_gem_version
    step :check_create_extension
    step :check_factories_moved_to_new_location
    step :check_bundle_install
    step :check_default_task
    step :check_run_specs
    step :check_sandbox
  end

  private

  def check_solidus_cmd
    cd(tmp_path) do
      output = `#{solidus_cmd} -h`
      expect($?).to be_success
      expect(output).to include('Commands:')
    end
  end

  def check_gem_version
    gem_version_commands = ['version', '--version', '-v']
    gem_version = SolidusDevSupport::VERSION
    solidus_version = Spree.solidus_gem_version

    cd(tmp_path) do
      gem_version_commands.each do |gem_version_cmd|
        output = `#{solidus_cmd} #{gem_version_cmd}`
        expect($?).to be_success
        expect(output).to include("Solidus version #{solidus_version}")
        expect(output).to include("Solidus Dev Support version #{gem_version}")
      end
    end
  end

  def check_create_extension
    cd(tmp_path) do
      output = `#{solidus_cmd} extension #{extension_name}`
      expect($?).to be_success
      expect(output).to include(gemspec_name)
      expect(output).to include('.circleci')
    end

    cd(install_path) do
      aggregate_failures do
        %w[
          bin/console
          bin/rails
          bin/rails-engine
          bin/rails-sandbox
          bin/sandbox
          bin/setup
        ].each do |bin|
          bin = Pathname(bin)
          expect(
            name: bin,
            exist: bin.exist?,
            executable: bin.stat.executable?
          ).to eq(
            name: bin,
            exist: true,
            executable: true
          )
        end
      end
    end
  end

  def check_factories_moved_to_new_location
    lib = Pathname(File.join(install_path, "lib/solidus_test_extension"))

    # Simulate what we can find on old extensions
    FileUtils.mv(lib.join("testing_support/factories.rb"), lib.join("factories.rb"))
    FileUtils.rmdir(lib.join("testing_support"))
    FileUtils.mkdir(lib.join("factories"))

    cd(install_path) do
      # Executing the `solidus extension .` command again, will ask user prompt
      # to override the factories file we moved in the new postion.
      expect(Thor::LineEditor).to receive(:readline).and_return("n")
      sh('solidus extension .')

      expect(lib.join("testing_support/factories.rb")).to exist
      expect(lib.join("testing_support/factories")).to exist
    end
  end

  def check_bundle_install
    cd(install_path) do
      open('Gemfile', 'a') { |f| f.puts "gem 'solidus_dev_support', path: '../../..'" }
    end

    expect { bundle_install }.to raise_error(command_failed_error, /invalid gemspec/)

    # Update gemspec with the required fields
    gemspec_path = install_path.join(gemspec_name)
    gemspec = gemspec_path.read.lines
    gemspec.grep(/spec\.author/).first.replace("  spec.author = 'John Doe'\n")
    gemspec.grep(/spec\.email/).first.replace("  spec.email = 'john@example.com'\n")
    gemspec.grep(/spec\.summary/).first.replace("  spec.summary = 'A nice extension'\n")
    gemspec.grep(/spec\.description/).first.replace("  spec.description = 'A super nice extension'\n")
    gemspec_path.write(gemspec.join)

    expect(bundle_install).to match(/Bundle complete/)
  end

  def check_default_task
    cd(install_path) do
      output = sh('bin/rake')
      expect(output).to include('Generating dummy Rails application')
      expect(output).to include('0 examples, 0 failures')
    end
  end

  def check_run_specs
    install_path.join('lib', 'solidus_test_extension', 'testing_support', 'factories.rb').open('a') do |factories_file|
      factories_file.write "\n puts 'loading test_extension factories'"
    end

    install_path.join('spec', 'some_spec.rb').write(
      "require 'spec_helper'\nRSpec.describe 'Some test' do it { expect(true).to be_truthy } end\n"
    )
    cd(install_path) do
      output = sh('bundle exec rspec')
      expect(output).to include('loading test_extension factories')
      expect(output).to include('1 example, 0 failures')
      expect(output).to include(ENV['CODECOV_TOKEN'] ? 'Coverage reports upload successfully' : 'Provide a CODECOV_TOKEN environment variable to enable Codecov uploads')
    end
  end

  def check_sandbox
    cd(install_path) do
      # rubocop:disable Lint/InterpolationCheck
      command = 'bin/rails-sandbox runner "puts %{The version of SolidusTestExtension is #{SolidusTestExtension::VERSION}}"'
      # rubocop:enable Lint/InterpolationCheck

      first_run_output = sh(command)
      expect(first_run_output).to include("Creating the sandbox app...")
      expect(first_run_output).to include('The version of SolidusTestExtension is 0.0.1')

      second_run_output = sh(command)
      expect(second_run_output).not_to include("Creating the sandbox app...")
      expect(second_run_output).to include('The version of SolidusTestExtension is 0.0.1')
    end
  end

  def sh(*args)
    command = args.size == 1 ? args.first : args.shelljoin
    output, status = with_unbundled_env { Open3.capture2e(command) }

    if status.success?
      output.to_s
    else
      if $DEBUG
        warn '~' * 80
        warn "$ #{command}"
        warn output.to_s
      end
      raise(command_failed_error, "command failed: #{command}\n#{output}")
    end
  end

  def with_unbundled_env(&block)
    if Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env(&block)
    else
      Bundler.with_clean_env(&block)
    end
  end

  def bundle_install
    # Optimize the bundle path within the CI, in this context using bundler env
    # variables doesn't help because commands are run with a clean env.
    bundle_path = "#{gem_root}/vendor/bundle"

    command = 'bundle install'
    command += " --path=#{bundle_path.shellescape}" if File.exist?(bundle_path)

    output = nil
    cd(install_path) { output = sh command }
    output
  end
end
