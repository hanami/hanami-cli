# frozen_string_literal: true

require "dry/inflector"
require_relative "../../errors"

module Hanami
  module CLI
    module Commands
      module Gem
        # @api private
        class New < Command
          FORBIDDEN_APP_NAMES = %w[app slice].freeze

          HEAD_DEFAULT = false
          GEM_SOURCE_DEFAULT = "rubygems.org"

          SKIP_INSTALL_DEFAULT = false
          SKIP_ASSETS_DEFAULT = false
          SKIP_DB_DEFAULT = false
          SKIP_VIEW_DEFAULT = false
          SKIP_MAILER_DEFAULT = false
          SKIP_GIT_DEFAULT = false

          DATABASE_SQLITE = "sqlite"
          DATABASE_POSTGRES = "postgres"
          DATABASE_MYSQL = "mysql"
          SUPPORTED_DATABASES = [DATABASE_SQLITE, DATABASE_POSTGRES, DATABASE_MYSQL].freeze

          TEMPLATE_ENGINE_DEFAULT = "erb"

          TEST_FRAMEWORK_DEFAULT = "rspec"
          TEST_FRAMEWORK_RSPEC = "rspec"
          TEST_FRAMEWORK_MINITEST = "minitest"

          desc "Generate a new Hanami app"

          argument :app, required: true, desc: "App name"

          option :head, type: :flag, required: false,
            default: HEAD_DEFAULT,
            desc: "Use Hanami HEAD version (from GitHub `main` branches)"

          option :gem_source, required: true,
            default: GEM_SOURCE_DEFAULT,
            desc: "Where to source Ruby gems from"

          option :skip_install, type: :flag, required: false,
            default: SKIP_INSTALL_DEFAULT,
            desc: "Skip app installation (Bundler, third-party Hanami plugins)"

          option :skip_assets, type: :flag, required: false,
            default: SKIP_ASSETS_DEFAULT,
            desc: "Skip including hanami-assets"

          option :skip_db, type: :flag, required: false,
            default: SKIP_DB_DEFAULT,
            desc: "Skip including hanami-db"

          option :skip_view, type: :flag, required: false,
            default: SKIP_VIEW_DEFAULT,
            desc: "Skip including hanami-view"

          option :skip_mailer, type: :flag, required: false,
            default: SKIP_MAILER_DEFAULT,
            desc: "Skip including hanami-mailer"

          option :skip_git, type: :flag, required: false,
            default: SKIP_GIT_DEFAULT,
            desc: "Skip git repository initialization (and `.gitignore' generation)"

          option :database, type: :string, required: false,
            default: DATABASE_SQLITE,
            desc: "Database adapter (supported: sqlite, mysql, postgres)"

          option :name, type: :string, required: false,
            desc: "App name to use for the module namespace"

          option :template_engine, type: :string, required: false,
            values: %w[erb haml slim],
            default: TEMPLATE_ENGINE_DEFAULT,
            desc: "Default template engine to use with generators"

          option :test, type: :string, required: false,
            values: %w[rspec minitest],
            default: TEST_FRAMEWORK_DEFAULT,
            desc: "Test framework (supported: rspec, minitest)"

          # rubocop:disable Layout/LineLength
          example [
            "bookshelf                                    # Generate a new Hanami app in `bookshelf/' directory, using `Bookshelf' namespace",
            "bookshelf --head                             # Generate a new Hanami app, using Hanami HEAD version from GitHub `main' branches",
            "bookshelf --gem-source=gem.coop              # Generate a new Hanami app, using https://gem.coop as Ruby gem source",
            "bookshelf --skip-install                     # Generate a new Hanami app, but it skips Hanami installation",
            "bookshelf --skip-assets                      # Generate a new Hanami app without hanami-assets",
            "bookshelf --skip-db                          # Generate a new Hanami app without hanami-db",
            "bookshelf --skip-view                        # Generate a new Hanami app without hanami-view",
            "bookshelf --skip-mailer                      # Generate a new Hanami app without hanami-mailer",
            "bookshelf --skip-git                         # Generate a new Hanami app without git repository initialization",
            "bookshelf --database={sqlite|postgres|mysql} # Generate a new Hanami app with a specified database (default: sqlite)",
            "bookshelf --template-engine={erb|haml|slim}  # Generate a new Hanami app which will use HAML for templates by default (default: erb)",
            "bookshelf --test={rspec|minitest}            # Generate a new Hanami app with specified test framework (default: rspec)",
            "my_bookshelf --name=bookshelf                # Generate a new Hanami app in `my_bookshelf/' directory, using `Bookshelf' namespace"
          ]
          # rubocop:enable Layout/LineLength

          def initialize(bundler: nil, generator: nil, system_call: SystemCall.new)
            @bundler = bundler
            @generator = generator
            @system_call = system_call
          end

          # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity

          def call(
            app:,
            head: HEAD_DEFAULT,
            gem_source: GEM_SOURCE_DEFAULT,
            skip_install: SKIP_INSTALL_DEFAULT,
            skip_assets: SKIP_ASSETS_DEFAULT,
            skip_db: SKIP_DB_DEFAULT,
            skip_view: SKIP_VIEW_DEFAULT,
            skip_mailer: SKIP_MAILER_DEFAULT,
            skip_git: SKIP_GIT_DEFAULT,
            database: nil,
            name: nil,
            template_engine: TEMPLATE_ENGINE_DEFAULT,
            test: TEST_FRAMEWORK_DEFAULT
          )
            directory = inflector.underscore(app)
            app = inflector.underscore(name || app)

            raise PathAlreadyExistsError.new(directory) if fs.exist?(directory)
            raise ForbiddenAppNameError.new(app) if FORBIDDEN_APP_NAMES.include?(app)

            normalized_database ||= normalize_database(database)

            fs.mkdir(directory)
            fs.chdir(directory) do
              context = Generators::Context.new(
                inflector,
                app,
                head:,
                gem_source:,
                skip_assets:,
                skip_db:,
                skip_view:,
                skip_mailer:,
                skip_git:,
                database: normalized_database,
                template_engine:,
                test_framework: test
              )
              generator.call(app, context: context) do
                if skip_install
                  puts "Skipping installation, please enter `#{app}' directory and run `bundle exec hanami install'"
                else
                  puts "Running bundle install..."
                  bundler.install!

                  unless skip_assets
                    puts "Running npm install..."
                    system_call.call("npm", ["install"]).tap do |result|
                      unless result.successful?
                        puts "NPM ERROR:"
                        puts(result.stderr.lines.map { |line| line.prepend("    ") })
                      end
                    end
                  end

                  puts "Running hanami install..."
                  run_install_command!(head: head)

                  puts "Running bundle binstubs hanami-cli rake..."
                  install_binstubs!

                  unless skip_git
                    puts "Initializing git repository..."
                    init_git_repository
                  end
                end
              end
            end
          end
          # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

          private

          def bundler
            @bundler ||= CLI::Bundler.new(fs:)
          end

          def generator
            @generator ||= Generators::Gem::App.new(fs:, inflector:)
          end

          attr_reader :system_call

          def normalize_database(database)
            case database
            when nil, "sqlite", "sqlite3"
              DATABASE_SQLITE
            when "mysql", "mysql2"
              DATABASE_MYSQL
            when "postgres", "postgresql", "pg"
              DATABASE_POSTGRES
            else
              raise DatabaseNotSupportedError.new(database, SUPPORTED_DATABASES)
            end
          end

          def run_install_command!(head:)
            head_flag = head ? " --head" : ""
            bundler.exec("hanami install#{head_flag}").tap do |result|
              if result.successful?
                bundler.exec("check").successful? || bundler.exec("install")
              else
                raise HanamiInstallError.new(result.stderr)
              end
            end
          end

          # @api private
          def install_binstubs!
            bundler.bundle("binstubs hanami-cli rake")
          end

          # @api private
          def init_git_repository
            system_call.call("git", ["init"]).tap do |result|
              unless result.successful?
                puts "WARNING: Failed to initialize git repository"
                puts(result.stderr.lines.map { |line| line.prepend("    ") })
              end
            end
          end
        end
      end
    end
  end
end
