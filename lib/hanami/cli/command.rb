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
    end
  end
end
