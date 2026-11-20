# frozen_string_literal: true

require "delegate"

module Hanami
  module Console
    module Plugins
      # @api private
      class SliceReaders < Module
        def initialize(app)
          super()

          @app = app
          @slice_names = []

          refresh
        end

        # Defines a reader for each of the app's slices, and removes the readers for slices that
        # are gone.
        #
        # Call this after reloading the app, since a reload can add or remove slices. The console
        # includes this module, so the change shows up there right away.
        #
        def refresh
          slice_names = @app.slices.keys.map(&:to_sym)

          (@slice_names - slice_names).each { |slice_name| remove_method(slice_name) }
          (slice_names - @slice_names).each { |slice_name| define_reader(slice_name) }

          @slice_names = slice_names
        end

        private

        def define_reader(slice_name)
          app = @app

          define_method(slice_name) do |*args, **kwargs, &block|
            # The console object can already have a method of this name, from a user extension or
            # from Object, like `class` or `system`. Defer to it, so the reader never hides it.
            # Some REPL code calls these methods on the console object (Pry calls `class` and
            # `method`, for example). Such a slice is still at `app.slices[:name]`.
            return super(*args, **kwargs, &block) if defined?(super)

            # Looked up on each call rather than closed over, because reloading the app replaces
            # its slice classes. Closing over the slice would leave the console handing out a
            # class whose container had already been discarded.
            app.slices[slice_name]
          end
        end
      end
    end
  end
end
