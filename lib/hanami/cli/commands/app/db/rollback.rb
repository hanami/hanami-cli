# frozen_string_literal: true

require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          class Rollback < DB::Command
            desc "Rollback database to a previous migration"

            argument :steps, desc: "Number of migrations to rollback", required: false
            option :target, desc: "Target migration number", aliases: ["-t"]
            option :dump, desc: "Dump structure after rolling back", default: true
            option :gateway, required: false, desc: "Use database for gateway"

            # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            def call(
              steps: nil,
              app: false,
              slice: nil,
              gateway: nil,
              target: nil,
              dump: true,
              **
            )
              # We allow either a number of steps or a target migration number to be provided
              # If steps is provided and target is not, we use steps as the target migration number, but we also have to
              # make sure steps is a number, hence some additional logic around checking and converting to number
              target = steps if steps && !target && !code_is_number?(steps)
              steps_count = steps && code_is_number?(steps) ? Integer(steps) : 1

              database = resolve_target_database(app: app, slice: slice, gateway: gateway)
              return unless database

              migration_code, migration_name = find_migration_target(target, steps_count, database)

              if migration_name.nil?
                output = if steps && code_is_number?(steps)
                           "==> migration file for #{steps} steps back was not found"
                         elsif target
                           "==> migration file for target #{target} was not found"
                         else
                           "==> no migrations to rollback"
                         end

                puts output
                return
              end

              measure "database #{database.name} rolled back to #{migration_name}" do
                database.run_migrations(target: Integer(migration_code))
                true
              end

              if dump && !re_running_in_test?
                run_command(
                  Structure::Dump,
                  app: database.slice == self.app,
                  slice: database.slice == self.app ? nil : database.slice.slice_name.to_s,
                  gateway: database.gateway_name == :default ? nil : database.gateway_name.to_s
                )
              end

              re_run_development_command_in_test
            end
            # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

            private

            def resolve_target_database(app:, slice:, gateway:)
              if gateway && !app && !slice
                stderr.puts "When specifying --gateway, an --app or --slice must also be given"
                throw :exit, 1
              end

              if slice
                resolve_slice_database(slice, gateway)
              elsif app
                resolve_app_database(gateway)
              else
                resolve_default_database
              end
            end

            def resolve_slice_database(slice_name, gateway)
              slice = resolve_slice(slice_name)
              return unless slice

              databases = build_databases(slice)

              if gateway
                database = databases[gateway.to_sym]
                unless database
                  stderr.puts %(No gateway "#{gateway}" found in slice "#{slice_name}")
                  throw :exit, 1
                end
                database
              elsif databases.size == 1
                databases.values.first
              else
                stderr.puts "Multiple gateways found in slice #{slice_name}. Please specify --gateway option."
                throw :exit, 1
              end
            end

            def resolve_app_database(gateway)
              databases = build_databases(app)

              if gateway
                database = databases[gateway.to_sym]
                unless database
                  stderr.puts %(No gateway "#{gateway}" found in app)
                  throw :exit, 1
                end
                database
              elsif databases.size == 1
                databases.values.first
              else
                stderr.puts "Multiple gateways found in app. Please specify --gateway option."
                throw :exit, 1
              end
            end

            def resolve_default_database
              all_dbs = all_databases

              if all_dbs.empty?
                stderr.puts "No databases found"
                throw :exit, 1
              elsif all_dbs.size == 1
                all_dbs.first
              else
                app_databases = build_databases(app)
                if app_databases.size == 1
                  app_databases.values.first
                elsif app_databases.size > 1
                  stderr.puts "Multiple gateways found in app. Please specify --gateway option."
                  throw :exit, 1
                else
                  stderr.puts "Multiple database contexts found. Please specify --app or --slice option."
                  throw :exit, 1
                end
              end
            end

            def resolve_slice(slice_name)
              slice_name_sym = inflector.underscore(Shellwords.shellescape(slice_name)).to_sym
              slice = app.slices[slice_name_sym]

              unless slice
                stderr.puts %(Slice "#{slice_name}" not found)
                throw :exit, 1
              end

              ensure_database_slice(slice)
              slice
            end

            # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            def find_migration_target(target, steps_count, database)
              applied_migrations = database.applied_migrations

              return if applied_migrations.empty?

              if applied_migrations.one? && target.nil?
                return initial_state(applied_migrations)
              end

              if target
                migration = applied_migrations.detect { |m| m.split("_").first == target }
                migration_code = migration&.split("_")&.first
                migration_name = migration ? File.basename(migration, ".*") : nil
              else
                # When rolling back N steps, we want to target the migration that is N steps back
                # If we have migrations [A, B, C, D] and want to rollback 2 steps from D,
                # we want to target B (index -3, since we go back 2 steps + 1 for the target)
                target_index = -(steps_count + 1)

                if target_index.abs > applied_migrations.size
                  return initial_state(applied_migrations)
                else
                  migration = applied_migrations[target_index]
                  migration_code = migration&.split("_")&.first
                  migration_name = migration ? File.basename(migration, ".*") : nil
                end
              end

              [migration_code, migration_name]
            end
            # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

            def initial_state(applied_migrations)
              migration = applied_migrations.first

              migration_code = Integer(migration.split("_").first) - 1
              migration_name = "initial state"

              [migration_code, migration_name]
            end

            def code_is_number?(code)
              code&.to_s&.match?(/^\d+$/) && !code.to_s.match?(/^\d{10,}$/)
            end
          end
        end
      end
    end
  end
end
