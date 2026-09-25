# frozen_string_literal: true

# SystemCall#call is adapted from hanami-devtools as well as the Bundler source code. Bundler is
# released under the MIT license: https://github.com/bundler/bundler/blob/master/LICENSE.md.
#
# Thank you to the Bundler maintainers and contributors.

require "open3"

module Hanami
  module CLI
    # Facility for making convenient system calls and returning their results.
    #
    # @since 2.0.0
    # @api public
    class SystemCall
      # The result of a system call. Provides access to its captured {#stdout} and {#stderr}, plus
      # whether the command executed successfully.
      #
      # @since 2.0.0
      # @api public
      class Result
        SUCCESSFUL_EXIT_CODE = 0
        private_constant :SUCCESSFUL_EXIT_CODE

        # Returns the command's exit code
        #
        # @return [Integer]
        #
        # @since 2.0.0
        # @api public
        attr_reader :exit_code

        # Returns the command's captured standard output.
        #
        # Returns `nil` when the output was streamed to a `stdout:` sink instead of captured.
        #
        # @return [String, nil]
        #
        # @since 2.0.0
        # @api public
        attr_reader :stdout

        # Returns the command's captured error output.
        #
        # Returns `nil` when the output was streamed to a `stderr:` sink instead of captured.
        #
        # @return [String, nil]
        #
        # @since 2.0.0
        # @api public
        attr_reader :stderr

        # @since 2.0.0
        # @api private
        def initialize(exit_code:, stdout:, stderr:)
          @exit_code = exit_code
          @stdout = stdout
          @stderr = stderr
        end

        # Returns true if the command executed successfully (if its {#exit_code} is 0).
        #
        # @return [Boolean]
        #
        # @since 2.0.0
        # @api public
        def successful?
          exit_code == SUCCESSFUL_EXIT_CODE
        end
      end

      # Executes the given system command and returns the result.
      #
      # By default the command's output is captured and made available on the {Result}. Pass
      # `stdout:` and/or `stderr:` to stream it to those sinks line by line as it arrives instead,
      # which is what you want for a long-running or interactive command. Streamed output is not
      # also captured, so the matching {Result} readers are `nil`; the sink is where it went.
      #
      # These are named to match a command's own {Dry::CLI::Command#stdout} and
      # {Dry::CLI::Command#stderr}, so a command can pass them along as `stdout:, stderr:`.
      #
      # @param cmd [String] the system command to execute
      # @param env [Hash<String, String>] an optional hash of environment variables to set before
      #   executing the command
      # @param stdout [IO, nil] an optional sink for the command's standard output, written to as
      #   the command runs
      # @param stderr [IO, nil] an optional sink for the command's error output, written to as the
      #   command runs
      # @param out_prefix [String] a string to prepend to each line written to `stdout` and `stderr`
      #
      # @overload call(cmd, env: {})
      #
      # @overload call(cmd, env: {}, &blk)
      #   Executes the command and passes the given block to the `Open3.popen3` method called
      #   internally.
      #
      #   @example
      #     call("info") do |stdin, stdout, stderr, wait_thread|
      #       # ...
      #     end
      #
      # @example Capturing the output
      #   result = system_call.call("npm", ["install"])
      #   result.stderr unless result.successful?
      #
      # @example Streaming the output as it arrives
      #   result = system_call.call("bin/dev", stdout:, stderr:)
      #   throw :exit, result.exit_code unless result.successful?
      #
      # @return [Result]
      #
      # @since 2.0.0
      # @api public
      def call(cmd, *args, env: {}, stdout: nil, stderr: nil, out_prefix: "")
        exit_code = nil
        captured_out = nil
        captured_err = nil

        ::Bundler.with_original_env do
          # Named for the child process, to leave `stdout:` and `stderr:` above meaning our sinks
          Open3.popen3(env, command(cmd, *args)) do |child_in, child_out, child_err, wait_thr|
            yield child_in, child_out, child_err, wait_thr if block_given?

            child_in.close

            # Read both streams before waiting on the process, to prevent deadlock. If we wait on
            # the process first, and the process writes enough data to fill the limited OS pipe
            # buffers, then the process will block waiting for us to read, while _we're_ blocked
            # waiting for it to finish. Reading first allows us to drain the buffers as output
            # arrives.
            out_thread = drain(child_out, stdout, out_prefix)
            err_thread = drain(child_err, stderr, out_prefix)

            captured_out = out_thread.value
            captured_err = err_thread.value
            exit_code = wait_thr&.value&.exitstatus
          end
        end

        Result.new(exit_code:, stdout: captured_out, stderr: captured_err)
      end

      # @since 2.1.0
      # @api public
      def command(cmd, *args)
        [cmd, args].flatten(1).compact.join(" ")
      end

      private

      # Reads `stream` to completion in its own thread.
      #
      # With a `sink`, each line is written there as it arrives and nothing is held onto, so a
      # command that runs for a long time doesn't accumulate its whole output in memory. Without
      # one, the output is read and returned for the {Result}.
      #
      # @return [Thread] yielding the captured output, or `nil` when it was streamed to a sink
      #
      # @since 3.0.0
      # @api private
      def drain(stream, sink, prefix)
        Thread.new do
          if sink
            stream.each_line { |line| sink.puts("#{prefix}#{line}") }
            nil
          else
            stream.read.strip
          end
        rescue IOError
          # The stream can be closed from under us when the command is interrupted
          nil
        end
      end
    end
  end
end
