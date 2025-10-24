# frozen_string_literal: true

module Hanami
  module CLI
    # Provides formatting utilities for CLI output including colors and icons
    #
    # There is significant overlap with Hanami-Utils ShellColor module, but hasn't been merged together yet.
    #
    # @api private
    # @since 2.3.0
    module Formatter
      # ANSI color codes
      COLORS = {
        reset: "\e[0m",
        bold: "\e[1m",
        green: "\e[32m",
        blue: "\e[34m",
        cyan: "\e[36m",
        yellow: "\e[33m",
        red: "\e[31m",
        gray: "\e[90m"
      }.freeze

      # Icons for different operations
      ICONS = {
        create: "✓",
        update: "↻",
        info: "→",
        warning: "⚠",
        error: "✗",
        success: "✓"
      }.freeze

      module_function

      # Wraps text in color codes
      #
      # @param text [String] the text to colorize
      # @param color [Symbol] the color name from COLORS
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] colorized text
      #
      # @api private
      def colorize(text, color, out: $stdout)
        return text unless out.tty?

        "#{COLORS[color]}#{text}#{COLORS[:reset]}"
      end

      # Formats a create message
      #
      # @param path [String] the path that was created
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def created(path, out: $stdout)
        icon = colorize(ICONS[:create], :green, out: out)
        label = colorize("create", :green, out: out)
        "  #{icon} #{label}  #{path}"
      end

      # Formats a create directory message
      #
      # @param path [String] the directory path that was created
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def created_directory(path, out: $stdout)
        icon = colorize(ICONS[:create], :green, out: out)
        label = colorize("create directory", :green, out: out)
        "#{icon} #{label}  #{path}"
      end

      # Formats an update message
      #
      # @param path [String] the path that was updated
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def updated(path, out: $stdout)
        icon = colorize(ICONS[:update], :cyan, out: out)
        label = colorize("update", :cyan, out: out)
        "  #{icon} #{label}  #{path}"
      end

      # Formats an info message
      #
      # @param text [String] the message text
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def info(text, out: $stdout)
        icon = colorize(ICONS[:info], :blue, out: out)
        "#{icon} #{text}"
      end

      # Formats a success message
      #
      # @param text [String] the message text
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def success(text, out: $stdout)
        icon = colorize(ICONS[:success], :green, out: out)
        label = colorize("✓", :green, out: out)
        "#{label} #{colorize(text, :green, out: out)}"
      end

      # Formats a warning message
      #
      # @param text [String] the message text
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def warning(text, out: $stdout)
        icon = colorize(ICONS[:warning], :yellow, out: out)
        label = colorize("warning", :yellow, out: out)
        "#{icon} #{label} #{text}"
      end

      # Formats an error message
      #
      # @param text [String] the message text
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted message
      #
      # @api private
      def error(text, out: $stdout)
        icon = colorize(ICONS[:error], :red, out: out)
        label = colorize("error", :red, out: out)
        "#{icon} #{label} #{text}"
      end

      # Formats a section header
      #
      # @param text [String] the header text
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted header
      #
      # @api private
      def header(text, out: $stdout)
        "\n#{colorize(text, :bold, out: out)}"
      end

      # Formats a dim/secondary text
      #
      # @param text [String] the text to dim
      # @param out [IO] the output stream to check for TTY (defaults to $stdout)
      # @return [String] formatted text
      #
      # @api private
      def dim(text, out: $stdout)
        text # No special dim color, just return plain text for now
      end
    end
  end
end
