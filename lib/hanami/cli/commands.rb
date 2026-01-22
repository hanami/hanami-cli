# frozen_string_literal: true

module Hanami
  module CLI
    # Returns true if the CLI is being called from inside an Hanami app.
    #
    # This is typically used to determine whether to register commands that are applicable either
    # inside or outside an app.
    #
    # @return [Boolean]
    #
    # @api private
    # @since 2.0.0
    def self.within_hanami_app?
      require "hanami"

      !!Hanami.app_path
    rescue LoadError => exception
      # Only rescue:
      #
      # 1. LoadError, due to hanami itself being missing, or
      # 2. Gem::LoadError, indicating gem version conflicts or other gem-related issues while
      #    loading hanami.
      #
      # This allows us to work around global gem version conflicts (e.g. with gems like bigdecimal,
      # which can come bundled with Ruby while also being upgraded independently) while still
      # raising errors for other missing requires.
      raise exception unless exception.path == "hanami" || exception.is_a?(Gem::LoadError)

      # If we can't load the hanami gem, fall back to a simple file check.
      File.exist?("config/app.rb")
    end

    # Contains the commands available for the current `hanami` CLI execution, depending on whether
    # the CLI is executed inside or outside an Hanami app.
    #
    # @see .within_hanami_app?
    #
    # @api public
    # @since 2.0.0
    module Commands
    end

    # @api private
    def self.register_commands!(within_hanami_app = within_hanami_app?)
      commands = if within_hanami_app
                   require_relative "commands/app"
                   Commands::App
                 else
                   require_relative "commands/gem"
                   Commands::Gem
                 end

      extend(commands)
    end
  end
end
