# frozen_string_literal: true

require "delegate"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            # @since 2.2.0
            class Database
              class DumpResult < DelegateClass(Hanami::CLI::SystemCall::Result)
                def initialize(result, post_process: -> sql { sql })
                  @post_process = post_process
                  super(result)
                end

                def sql
                  @post_process.call(stdout)
                end
              end

              DATABASE_CLASS_RESOLVER = {
                sqlite: -> {
                  require_relative("sqlite")
                  Sqlite
                },
                postgres: -> {
                  require_relative("postgres")
                  Postgres
                },
                mysql: -> {
                  require_relative("mysql")
                  Mysql
                }
              }.freeze

              def self.database_class(database_url)
                # Required here rather than at the top of this file, since every app command loads
                # this file, including in apps that do not use hanami-db.
                require "hanami-db"

                adapter = Hanami::DB::DatabaseURL.adapter(database_url)

                DATABASE_CLASS_RESOLVER.fetch(adapter) {
                  ensure_parseable(database_url)

                  scheme = Hanami::DB::DatabaseURL.scheme(database_url) || "(none)"
                  raise Hanami::CLI::UnsupportedDatabaseSchemeError.new(scheme)
                }.call
              end

              # Re-raises hanami-db's error for URLs that cannot be parsed as a CLI error, so the CLI
              # prints its message rather than a backtrace.
              def self.ensure_parseable(database_url)
                Hanami::DB::DatabaseURL.uri(database_url)
              rescue Hanami::DB::InvalidDatabaseURLError => exception
                raise Hanami::CLI::Error, exception.message
              end
              private_class_method :ensure_parseable

              def self.from_slice(slice:, system_call:)
                provider = slice.container.providers[:db]
                raise "No :db provider for #{slice}" unless provider

                provider.source.database_urls.map { |(gateway_name, database_url)|
                  database = database_class(database_url).new(
                    slice: slice,
                    gateway_name: gateway_name,
                    system_call: system_call
                  )

                  [gateway_name, database]
                }.to_h
              end

              attr_reader :slice
              attr_reader :gateway_name

              attr_reader :system_call

              def initialize(slice:, gateway_name:, system_call:)
                @slice = slice
                @gateway_name = gateway_name
                @system_call = system_call
              end

              def name
                database_uri.path.sub(%r{^/}, "")
              end

              def database_url
                slice.container.providers[:db].source.database_urls.fetch(gateway_name)
              end

              # Parses the URL nested in JDBC URLs (required to connect via JRuby), e.g.
              # "jdbc:postgresql://localhost/app".
              def database_uri
                @database_uri ||= Hanami::DB::DatabaseURL.uri(database_url)
              end

              # JDBC drivers expect the user and password as query params, e.g.
              # "jdbc:postgresql://localhost/app?user=postgres&password=secret".
              #
              # URI leaves userinfo percent-encoded, so decode it to match what Sequel logs in with. Query
              # params are already decoded by `database_query_params`.
              def database_user
                decode_userinfo(database_uri.user) || database_query_params["user"]
              end

              def database_password
                decode_userinfo(database_uri.password) || database_query_params["password"]
              end

              def decode_userinfo(value)
                URI.decode_uri_component(value) if value
              end

              def gateway
                slice["db.config"].gateways[gateway_name]
              end

              def connection
                gateway.connection
              end

              def exec_create_command
                raise Hanami::CLI::NotImplementedError
              end

              def exec_drop_command
                raise Hanami::CLI::NotImplementedError
              end

              def exists?
                raise Hanami::CLI::NotImplementedError
              end

              def exec_dump_command
                raise Hanami::CLI::NotImplementedError
              end

              def exec_load_command
                raise Hanami::CLI::NotImplementedError
              end

              def run_migrations(**options)
                require "rom/sql"
                ROM::SQL.with_gateway(gateway) do
                  migrator.run(options)
                end
              end

              def migrator
                @migrator ||= begin
                  slice.prepare :db

                  require "rom/sql"
                  ROM::SQL::Migration::Migrator.new(connection, path: migrations_path)
                end
              end

              def sequel_migrator
                @sequel_migrator ||= begin
                  slice.prepare :db

                  require "sequel"
                  Sequel.extension :migration

                  require "rom/sql"
                  ROM::SQL.with_gateway(gateway) do
                    Sequel::TimestampMigrator.new(migrator.connection, migrations_path, {})
                  end
                end
              end

              def applied_migrations
                sequel_migrator.applied_migrations
              end

              def db_config_path
                slice.root.join("config", "db")
              end

              def db_config_dir?
                db_config_path.directory?
              end

              def migrations_path
                if gateway_name == :default
                  db_config_path.join("migrate")
                else
                  db_config_path.join("#{gateway_name}_migrate")
                end
              end

              def migrations_dir?
                migrations_path.directory?
              end

              def structure_file
                path = slice.root.join("config", "db")

                if gateway_name == :default
                  path.join("structure.sql")
                else
                  path.join("#{gateway_name}_structure.sql")
                end
              end

              def structure_sql_dump
                DumpResult.new(exec_dump_command, post_process: method(:post_process_dump))
              end

              def schema_migrations_sql_dump
                return unless migrations_dir?

                sql = +"INSERT INTO schema_migrations (filename) VALUES\n"
                sql << applied_migrations.map { |v| "('#{v}')" }.join(",\n")
                sql << ";"
                sql
              end

              private

              def database_query_params
                @database_query_params ||= URI.decode_www_form(database_uri.query.to_s).to_h
              end

              def jruby?
                RUBY_ENGINE == "jruby"
              end

              def post_process_dump(sql)
                sql
              end
            end
          end
        end
      end
    end
  end
end
