# frozen_string_literal: true

require_relative "plugins/slice_readers"
require_relative "plugins/unbooted_slice_warnings"

module Hanami
  # @since 2.0.0
  # @api private
  module Console
    # Hanami app console context
    #
    # @since 2.0.0
    # @api private
    class Context < Module
      attr_reader :app

      # @since 2.0.0
      # @api private
      def initialize(app)
        super()
        @app = app

        define_context_methods
        include Plugins::SliceReaders.new(app)

        Plugins::UnbootedSliceWarnings.activate
      end

      # Reloads the app in place, for the console's `reload` method.
      #
      # Reloading in place keeps the session: local variables, history and anything else built up
      # so far survive, where re-execing the console threw all of it away.
      #
      # Constants captured before the reload are the exception. They still point at the classes
      # they did when they were captured, so anything held in a variable is stale afterwards.
      #
      # @api private
      # @since 3.1.0
      def self.reload_app(app)
        # Either an older Hanami without in-place reloading, or an app that has it turned off.
        unless app.respond_to?(:reload) && app.config.code_reloading
          puts "Reloading..."
          return Kernel.exec("#{$PROGRAM_NAME} console")
        end

        print "Reloading... "

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          app.reload
        rescue StandardError, ScriptError
          # Finish the line before the console prints the error. ScriptError covers a SyntaxError
          # in a file loaded during the reload. Hanami can unload a slice that failed part way
          # through preparing, so calling `reload` again after a fix gets back to a working app.
          puts "failed. Fix the error, then call `reload` again."
          raise
        end
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

        puts "done (#{(elapsed * 1000).round}ms)"
      end

      private

      def define_context_methods
        hanami_app = app

        define_method(:inspect) do
          "#<#{self.class} app=#{hanami_app} env=#{hanami_app.config.env}>"
        end

        define_method(:app) do
          hanami_app
        end

        define_method(:reload) do
          Context.reload_app(hanami_app)
        end

        # The app has no `reload!`, so without this it would raise NoMethodError via
        # #method_missing. It is a common enough thing to reach for, since Rails uses it, that it
        # should do the same as `reload`.
        define_method(:reload!) do
          Context.reload_app(hanami_app)
        end

        define_method(:method_missing) do |name, *args, &block|
          return hanami_app.public_send(name, *args, &block) if hanami_app.respond_to?(name)

          super(name, *args, &block)
        end

        define_method(:respond_to_missing?) do |name, include_private|
          super(name, include_private) || hanami_app.respond_to?(name, include_private)
        end

        # User-provided extension modules
        app.config.console.extensions.each do |mod|
          include mod
        end
      end
    end
  end
end
