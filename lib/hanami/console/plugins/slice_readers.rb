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

          app.slices.each do |slice|
            slice_name = slice.slice_name.to_sym

            # Looked up on each call rather than closed over, because reloading the app replaces
            # its slice classes. Closing over the slice would leave the console handing out a
            # class whose container had already been discarded.
            define_method(slice_name) do
              app.slices[slice_name]
            end
          end
        end
      end
    end
  end
end
