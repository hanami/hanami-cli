# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            # @since 2.2.0
            class Sqlite < Database
              # @api private
              # @since 2.2.0
              class Failure
                def initialize(err)
                  @err = err
                end

                attr_reader :err

                def successful? = false
                def exit_code = 1
              end

              # @api private
              # @since 2.2.0
              class Success
                def successful? = true
                def exit_code = 0
              end

              # @api private
              # @since 2.2.0
              def exec_create_command
                return Success.new if exists?

                FileUtils.mkdir_p(File.dirname(file_path))

                system_call.call(%(sqlite3 #{file_path} "VACUUM;"))
              end

              # @api private
              # @since 2.2.0
              def exec_drop_command
                begin
                  File.unlink(file_path) if exists?
                rescue => exception # rubocop:disable Style/RescueStandardError
                  # Mimic a system_call result
                  return Failure.new(exception.message)
                end

                # Mimic a system_call result
                Success.new
              end

              # @api private
              # @since 2.2.0
              def exists?
                File.exist?(file_path)
              end

              # @api private
              # @since 2.2.0
              def exec_dump_command
                system_call.call(%(sqlite3 #{file_path} ".schema --indent --nosys"))
              end

              # @api private
              # @since 2.2.0
              def exec_load_command
                system_call.call("sqlite3 #{file_path} < #{structure_file}")
              end

              # @api private
              # @since 2.2.0
              def name
                # Sequel expects sqlite:// URIs to operate the same as file:// URIs: 2 slashes for
                # a relative path, 3 for an absolute path. In the case of 2 slashes, the first part
                # of the path is considered by Ruby's `URI` as the `#host`.
                @name ||= "#{database_uri.host}#{database_uri.path}"
              end

              private

              def file_path
                @file_path ||=
                  if File.absolute_path?(name)
                    name
                  else
                    slice.app.root.join(name).to_s
                  end
              end
            end
          end
        end
      end
    end
  end
end
