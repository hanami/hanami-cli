# frozen_string_literal: true

require "dry/cli/style_mixin"

module Hanami
  module CLI
    # Named text styles for the `hanami` CLI's output.
    #
    # Use these rather than building styles inline, so our output looks the same across commands.
    #
    # Styles render only when written to a terminal. Output sent to a file or a pipe stays plain.
    #
    # Keep styled text unrendered until it reaches a stream: start with the styled part and join
    # with `+` (`SUCCESS["✓"] + " #{desc}"`), instead of interpolating it into a string.
    #
    # @see Dry::CLI::Style
    #
    # @api private
    # @since 3.0.0
    module Styles
      extend Dry::CLI::StyleMixin

      # Hanami's cherry blossom pink, for marking the steps a command takes.
      #
      # This shade stays pink on 16 color terminals (as bright magenta), instead of turning red and
      # looking like {FAILURE}.
      ACCENT = style.bold.hex("#ff5fa2")

      # Regular weight, since these mark many lines at once (like a list of created files), and
      # their color is enough to tell them apart.
      SUCCESS = style.green
      CHANGED = style.yellow

      WARNING = style.bold.yellow
      FAILURE = style.bold.red

      EMPHASIS = style.bold
      MUTED = style.dim
    end
  end
end
