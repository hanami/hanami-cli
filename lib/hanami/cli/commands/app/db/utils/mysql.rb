# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            class Mysql < Database
              # We need to know the executable name and what flavour is inside. These might be:
              # * mariadb executable, which means maradb flavour
              # * mysql executable with MariaDB inside
              # * otherwise we assume Oracle MySQL flavour
              # @api private
              Env = Data.define(:executable, :flavour)

              # @api private
              def exec_create_command
                return true if exists?

                exec_cli(env.executable, %(-e "CREATE DATABASE #{escaped_name}"))
              end

              # @api private
              # @since 2.2.0
              def exec_drop_command
                return true unless exists?

                exec_cli(env.executable, %(-e "DROP DATABASE #{escaped_name}"))
              end

              # @api private
              # @since 2.2.0
              def exists?
                result = exec_cli(env.executable, %(-e "SHOW DATABASES LIKE '#{name}'" --batch))
                raise Hanami::CLI::DatabaseExistenceCheckError.new(result.stderr) unless result.successful?

                result.stdout != ""
              end

              # @api private
              # @since 2.2.0
              def exec_dump_command
                executable = if env.executable == "mysql"
                               "mysqldump"
                             else
                               "mariadb-dump"
                             end

                gtid_option = env.flavour == :oracle ? "--set-gtid-purged=off" : ""

                exec_cli(
                  executable,
                  "--no-data --routines --skip-comments #{gtid_option} #{escaped_name}"
                )
              end

              # rubocop:disable Layout/LineLength
              # @api private
              # @since 2.2.0
              def exec_load_command
                commands_option = env.flavour == :oracle ? "--commands " : ""

                exec_cli(
                  env.executable,
                  %(#{commands_option}--execute "SET FOREIGN_KEY_CHECKS = 0; SOURCE #{structure_file}; SET FOREIGN_KEY_CHECKS = 1" --database #{escaped_name})
                )
              end
              # rubocop:enable Layout/LineLength

              private

              def escaped_name
                Shellwords.escape(name)
              end

              def exec_cli(cli_name, cli_args)
                system_call.call(
                  "#{cli_name} #{cli_options} #{cli_args}",
                  env: cli_env_vars
                )
              end

              def cli_options
                [].tap { |opts|
                  opts << "--host=#{Shellwords.escape(database_uri.host)}" if database_uri.host
                  opts << "--port=#{Shellwords.escape(database_uri.port)}" if database_uri.port
                  opts << "--user=#{Shellwords.escape(database_user)}" if database_user
                }.join(" ")
              end

              def cli_env_vars
                @cli_env_vars ||= {}.tap do |vars|
                  vars["MYSQL_PWD"] = database_password.to_s if database_password
                end
              end

              def env
                @env ||= begin
                  mariadb_path = `which mariadb`

                  if mariadb_path != ""
                    Env.new("mariadb", :mariadb)
                  elsif `mysql --version` =~ /MariaDB/
                    Env.new("mysql", :mariadb)
                  else
                    Env.new("mysql", :oracle)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
