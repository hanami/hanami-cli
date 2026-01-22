# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync. To update it, edit repo-sync.yml.

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami-cli"
  spec.authors       = ["Hanakai team"]
  spec.email         = ["info@hanakai.org"]
  spec.license       = "MIT"
  spec.version       = Hanami::CLI::VERSION.dup

  spec.summary       = "The CLI for the Hanami framework"
  spec.description   = spec.summary
  spec.homepage      = "https://hanamirb.org"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "hanami-cli.gemspec", "lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = Dir["exe/*"].map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/hanami/hanami-cli/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/hanami/hanami-cli"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/hanami/hanami-cli/issues"
  spec.metadata["funding_uri"]       = "https://github.com/sponsors/hanami"

  spec.required_ruby_version = ">= 3.2"

  spec.add_runtime_dependency "bundler", ">= 2.1"
  spec.add_runtime_dependency "dry-cli", "~> 1.0", ">= 1.1.0"
  spec.add_runtime_dependency "dry-files", "~> 1.0", ">= 1.0.2"
  spec.add_runtime_dependency "dry-inflector", "~> 1.0"
  spec.add_runtime_dependency "irb"
  spec.add_runtime_dependency "rake", "~> 13.0"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"
  spec.add_runtime_dependency "rackup"
end

