# frozen_string_literal: true

require "dry/cli"
require "dry/inflector"
require_relative "files"

module Hanami
  module CLI
    # Base class for `hanami` CLI commands.
    #
    # Commands are given their `stdin`, `stdout` and `stderr` streams by the CLI framework. Write
    # output via `puts` (or `stdout.puts` or `stdout.print`) and `stderr`.
    #
    # These, along with the {#fs}, are set before `#initialize` runs, so a subclass can declare its
    # own `#initialize` for its own arguments only, with no `super` to call. Anything built on top
    # of a stream should be built lazily (via a memoized reader method) rather than in
    # `#initialize`; see {Dry::CLI::Command} for why.
    #
    # @api public
    # @since 2.0.0
    class Command < Dry::CLI::Command
      # Adds the `fs:` to the auto-assigned `#initialize` args.
      #
      # @api private
      def self.auto_assign_keywords = super + %i[fs]

      # Returns the object for managing file system interactions.
      #
      # Unless given one, the command builds its own, which reports the files it creates and updates
      # to the command's own {Dry::CLI::Command#stdout}. It is built on first use, since a command
      # registered as an instance does not know its streams until after it is initialized.
      #
      # @return [Hanami::CLI::Files]
      #
      # @since 2.0.0
      # @api public
      def fs
        @fs ||= Hanami::CLI::Files.new(stdout:)
      end

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

      # Assigns the {.auto_assign_keywords} to the command, before `#initialize` runs.
      #
      # Calls `super` first, so anything assigned by `Dry::CLI::Command` is in place before ours.
      #
      # @see Dry::CLI::Command#auto_assign
      #
      # @since 2.0.0
      # @api public
      def auto_assign(fs: nil, **kwargs)
        super(**kwargs)
        @fs = fs
      end
    end
  end
end
