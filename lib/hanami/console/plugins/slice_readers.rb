# frozen_string_literal: true

require "delegate"

module Hanami
  module Console
    module Plugins
      # @api private
      # @since 2.0.0
      class SliceReaders < Module
        # @since 2.0.0
        # @api private
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
        # @api private
        # @since 3.1.0
        def refresh
          slice_names = @app.slices.keys.map(&:to_sym)

          (@slice_names - slice_names).each { |slice_name| remove_method(slice_name) }
          (slice_names - @slice_names).each { |slice_name| define_reader(slice_name) }

          @slice_names = slice_names
        end

        private

        def define_reader(slice_name)
          app = @app

          # Looked up on each call rather than closed over, because reloading the app replaces
          # its slice classes. Closing over the slice would leave the console handing out a class
          # whose container had already been discarded.
          define_method(slice_name) do
            app.slices[slice_name]
          end
        end
      end
    end
  end
end
