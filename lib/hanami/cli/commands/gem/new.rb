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
          example "bookshelf",                                    "Generate a new Hanami app in `bookshelf/' directory, using `Bookshelf' namespace"
          example "bookshelf --head",                             "Generate a new Hanami app, using Hanami HEAD version from GitHub `main' branches"
          example "bookshelf --gem-source=gem.coop",              "Generate a new Hanami app, using https://gem.coop as Ruby gem source"
          example "bookshelf --skip-install",                     "Generate a new Hanami app, but it skips Hanami installation"
          example "bookshelf --skip-assets",                      "Generate a new Hanami app without hanami-assets"
          example "bookshelf --skip-db",                          "Generate a new Hanami app without hanami-db"
          example "bookshelf --skip-view",                        "Generate a new Hanami app without hanami-view"
          example "bookshelf --skip-mailer",                      "Generate a new Hanami app without hanami-mailer"
          example "bookshelf --skip-git",                         "Generate a new Hanami app without git repository initialization"
          example "bookshelf --database={sqlite|postgres|mysql}", "Generate a new Hanami app with a specified database (default: sqlite)"
          example "bookshelf --template-engine={erb|haml|slim}",  "Generate a new Hanami app which will use HAML for templates by default (default: erb)"
          example "bookshelf --test={rspec|minitest}",            "Generate a new Hanami app with specified test framework (default: rspec)"
          example "my_bookshelf --name=bookshelf",                "Generate a new Hanami app in `my_bookshelf/' directory, using `Bookshelf' namespace"
          # rubocop:enable Layout/LineLength

          def initialize(
            bundler: CLI::Bundler.new(fs:),
            generator: Generators::Gem::App.new(fs:, inflector:),
            system_call: SystemCall.new
          )
            @bundler = bundler
            @generator = generator
            @system_call = system_call
          end

          # rubocop:disable Metrics/AbcSize

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
            directory = app.split("-").map { inflector.underscore(_1) }.join("-")
            app = inflector.underscore(name || app)

            raise PathAlreadyExistsError.new(directory) if fs.exist?(directory)
            raise ForbiddenAppNameError.new(app) if FORBIDDEN_APP_NAMES.include?(app)

            normalized_database ||= normalize_database(database)

            start = monotonic_time

            # This heading stands in for the directory's own "create" line
            heading("Creating #{directory}/")
            fs.mkdir(directory, report: false)
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
                  puts
                  puts Styles::WARNING[
                    "Skipping installation, please enter `#{directory}' directory and run `bundle exec hanami install'"
                  ]
                else
                  install(head:, skip_assets:, skip_git:)
                end
              end
            end

            print_next_steps(directory, start:) unless skip_install
          end
          # rubocop:enable Metrics/AbcSize

          private

          attr_reader :bundler
          attr_reader :generator
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

          # Installs the new app's gems and npm packages, runs `hanami install`, and initializes git.
          #
          # @api private
          def install(head:, skip_assets:, skip_git:)
            heading("Installing")

            step("bundle install") { bundler.install! }
            step("npm install") { system_call.call("npm", ["install"]) } unless skip_assets
            step("hanami install") { run_install_command!(head:) }
            step("bundle binstubs hanami-cli rake") { install_binstubs! }
            step("git init") { system_call.call("git", ["init"]) } unless skip_git
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

          # Prints a heading for the output that follows it. The blank line above sets it apart from
          # the output before it, or from the command the user typed.
          #
          # @api private
          def heading(text)
            puts
            puts Styles::EMPHASIS[text]
          end

          # Prints how long the app took to create (since `start`), then the commands to start
          # working on it. These match the "Getting started" steps in the app's README.
          #
          # @api private
          def print_next_steps(directory, start:)
            seconds = monotonic_time - start

            puts
            puts Styles::ACCENT["🌸 Your new Hanami app is ready!"] + " " + Styles::MUTED[format("(%.1fs)", seconds)]
            puts
            puts Styles::EMPHASIS["  cd #{directory}"]
            puts Styles::EMPHASIS["  bin/setup"]
            puts Styles::EMPHASIS["  bin/dev"]
            puts
            puts "View your app at http://localhost:2300"
            puts
            puts "📚 Learn more   https://hanakai.org/learn/hanami"
            puts "💬 Join us      https://hanakai.org/community"
          end
        end
      end
    end
  end
end
