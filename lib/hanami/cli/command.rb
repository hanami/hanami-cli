# frozen_string_literal: true

require "dry/cli"
require "dry/inflector"
require_relative "files"

module Hanami
  module CLI
    # Base class for `hanami` CLI commands.
    #
    # Along with the standard `Dry::CLI::Command` affordances, like `stdout` and `stderr` streams,
    # includes {#fs} for making filesystem changes and reporting each file it creates or updates.
    #
    # @see https://hanakai.org/learn/dry/dry-cli
    #
    # @api public
    # @since 2.0.0
    class Command < Dry::CLI::Command
      # The width of a step's ✓ or ✗ mark, with the indent before it. See {#step}.
      #
      # @api private
      STEP_MARK_WIDTH = 3
      private_constant :STEP_MARK_WIDTH

      # @api private
      private def auto_initialize(fs: nil, **kwargs)
        # `stdout` is available only after calling super
        super(**kwargs)
        @fs = fs || Hanami::CLI::Files.new(stdout:)
      end

      # Returns the object for managing file system interactions.
      #
      # Unless given one, the command builds its own, which reports the files it creates and updates
      # to the command's own {Dry::CLI::Command#stdout}.
      #
      # @return [Hanami::CLI::Files]
      #
      # @since 2.0.0
      # @api public
      attr_reader :fs

      # Returns the inflector for any command-level inflections.
      #
      # @return [Dry::Inflector]
      #
      # @since 2.0.0
      # @api public
      def inflector
        @inflector ||= Dry::Inflector.new
      end

      private

      # rubocop:disable Metrics/AbcSize

      # Runs the block as one step of a command, then prints a line with the step's result.
      #
      # While the block runs, shows a spinner on {Dry::CLI::Command#stderr} (when it is a terminal).
      # Nothing else should write output while the block runs, since it would mix with the spinner.
      #
      # The step fails if the block returns a falsey value or an unsuccessful {SystemCall::Result},
      # or if it raises an error. The error is raised again after the result line is printed. When
      # an unsuccessful {SystemCall::Result} fails the step, its stderr is printed below the line.
      #
      # The result line is indented to line up with the verbs of created and updated files. Its time
      # is left out when the step took less than a tenth of a second.
      #
      # @example
      #   step("bundle install") { bundler.install! }
      #   # printed to `stdout`:
      #   #   ✓ bundle install in 14.2s
      #
      # @return [Object] the block's return value
      def step(desc, &)
        start = monotonic_time
        succeeded = false

        result = Dry::CLI::Spinner::Dot.run(step_line(Styles::ACCENT["%{spinner}"], desc), stream: stderr, &)

        succeeded = result && (!result.respond_to?(:successful?) || result.successful?)
        result
      ensure
        if succeeded
          seconds = (monotonic_time - start).round(1)
          line = step_line(Styles::SUCCESS["✓"], desc)
          line += Styles::MUTED[format(" in %.1fs", seconds)] unless seconds.zero?
          stdout.puts line
        else
          stdout.puts step_line(Styles::FAILURE["✗"], desc)
          print_failure_output(result.stderr) if result.is_a?(SystemCall::Result)
        end
      end
      # rubocop:enable Metrics/AbcSize

      # Pads the mark assuming it is one character wide, including the spinner.
      def step_line(mark, desc)
        mark.rjust(mark.length + STEP_MARK_WIDTH - 1) + " #{desc}"
      end

      # Returns a time in seconds for measuring how long something takes.
      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # Prints the output of a failed step or system call, indented below the line that names it.
      def print_failure_output(output)
        lines = output.to_s.lines
        stdout.puts(lines.map { |line| "    #{line}" }) unless lines.empty?
      end
    end
  end
end
