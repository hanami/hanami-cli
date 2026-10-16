# frozen_string_literal: true

require "hanami/env"
require_relative "db/utils/database"
require_relative "../../files"

module Hanami
  module CLI
    module Commands
      module App
        # Base class for `hanami` CLI commands intended to be executed within an existing Hanami
        # app.
        #
        # @since 2.0.0
        # @api public
        class Command < Hanami::CLI::Command
          option :env, desc: "App environment (development, test, production)", aliases: ["e"]

          # Overloads {Hanami::CLI::Commands::App::Command#call} to ensure an appropriate
          # `HANAMI_ENV` environment variable is set.
          #
          # Uses an `--env` option if provided, then falls back to an already-set `HANAMI_ENV`
          # environment variable, and defaults to "development" in the absence of both.
          #
          # @since 2.0.0
          # @api private
          module Environment
            # @since 2.0.0
            # @api private
            def call(*args, **opts)
              env = opts[:env]

              hanami_env = env ? env.to_s : ENV.fetch("HANAMI_ENV", "development")

              ENV["HANAMI_ENV"] = hanami_env
              Hanami::Env.load

              # Pass only the params that the command's own `#call` declares, as Dry::CLI would if
              # this module's `#call` were not in the way.
              super(*args, **Dry::CLI::Dispatch.args_for(method(:call).super_method, opts))
            rescue FileAlreadyExistsError => exception
              stderr.puts(exception.message)
              exit(1)
            end
          end

          # Extends each command instance with {Environment}.
          #
          # This puts {Environment#call} ahead of the `#call` of every class in the command's
          # ancestors and only once, regardless of how deep the subclassing may go.
          #
          # @api private
          def self.new(...)
            super.extend(Environment)
          end

          # Returns the Hanami app class.
          #
          # @return [Hanami::App] the Hanami app
          #
          # @raise [Hanami::AppLoadError] if the app has not been loaded
          #
          # @since 2.0.0
          # @api public
          def app
            @app ||=
              begin
                require "hanami/prepare"
                Hanami.app
              end
          end

          def inflector = app.inflector

          # Runs another CLI command via its command class.
          #
          # @param klass [Hanami::CLI::Command]
          # @param args [Array] any additional arguments to pass to the command's `#call` method.
          #
          # @since 2.0.0
          # @api public
          def run_command(klass, ...)
            klass.new(stderr:, stdin:, stdout:, fs:).call(...)
          end

          # Executes a given block and prints string to the command's `stdout` stream with details
          # of the time taken to execute.
          #
          # If the block returns a falsey value, then a failure message is printed.
          #
          # @example
          #   measure("Reverse the polarity of the neutron flow") do
          #     # reverses the polarity, returns a truthy value
          #   end
          #   # printed to `stdout`:
          #   # => Reverse the polarity of the neutron flow in 2s
          #
          # @example
          #   measure("Disable the time dilation device") do
          #     # attempts to disable the device, returns a falsey favlue
          #   end
          #   # printed to `stdout`:
          #   # !!! => Disable the time dilation device FAILED
          #
          # @since 2.0.0
          # @api public
          def measure(desc)
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            result = yield
            stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            if result
              puts "=> #{desc} in #{(stop - start).round(4)}s"
            else
              puts "!!! => #{desc.inspect} FAILED"
            end
          end
        end
      end
    end
  end
end
