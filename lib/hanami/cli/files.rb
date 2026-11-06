# frozen_string_literal: true

require "dry/files"

module Hanami
  module CLI
    # @since 2.0.0
    # @api private
    class Files < Dry::Files
      REPORT_VERB_WIDTH = 8
      private_constant :REPORT_VERB_WIDTH

      # @since 2.0.0
      # @api private
      def initialize(stdout: $stdout, **args)
        super(**args)
        @stdout = Dry::CLI::Stream.for(stdout)
      end

      # @api private
      def create(path, *content, force: false)
        raise FileAlreadyExistsError.new(path) if exist?(path) and !force

        write(path, *content)
      end

      # @since 2.0.0
      # @api private
      def write(path, *content)
        already_exists = exist?(path)

        super

        delete_keepfiles(path) unless already_exists

        if already_exists
          updated(path)
        else
          created(path)
        end
      end

      # Pass `report: false` to make the directory without printing it, such as when a command has
      # already printed its own heading for the directory.
      #
      # @since 2.0.0
      # @api private
      def mkdir(path, report: true)
        return if exist?(path)

        super(path)
        created(dir_path(path)) if report
      end

      def touch(path)
        return if exist?(path)

        super
        created(path)
      end

      def block_contains?(path, target, contents)
        content = adapter.read(path)
        class_start = content.index(target)
        class_end = content.index(/(?:^|\s)#{CLOSE_BLOCK}(?:$|\s)/, class_start)
        content[class_start..class_end].include? contents
      end

      private

      attr_reader :stdout

      # Removes .keep files in any directories leading up to the given path.
      #
      # Does not attempt to remove `.keep` files in the following scenarios:
      #   - When the given path is a `.keep` file itself.
      #   - When the given path is absolute, since ascending up this path may lead to removal of
      #     files outside the Hanami project directory.
      def delete_keepfiles(path)
        path = Pathname(path)

        return if path.absolute?
        return if path.relative_path_from(path.dirname).to_s == ".keep"

        path.dirname.ascend do |part|
          keepfile = (part + ".keep").to_path
          delete(keepfile) if exist?(keepfile)
        end
      end

      def updated(path)
        report(Styles::CHANGED["update"], path)
      end

      def created(path)
        report(Styles::SUCCESS["create"], path)
      end

      # Prints a line for a change to a path, with its verb right-aligned so the paths line up:
      #
      #     create  app/actions/books/index.rb
      #     update  config/routes.rb
      def report(verb, path)
        path = path.to_s

        # A `.keep` file only holds its directory in place, so it matters less than the files around it
        path = Styles::MUTED[path] if ::File.basename(path) == ".keep"

        stdout.puts verb.rjust(REPORT_VERB_WIDTH) + "  " + path
      end

      def dir_path(path)
        path + ::File::SEPARATOR
      end
    end
  end
end
