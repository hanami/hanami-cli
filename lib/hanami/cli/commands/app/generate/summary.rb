# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # Prints a closing line after a generate command finishes, naming what it generated:
          #
          #     ✓ Generated action books.index
          #
          # The line follows the list of created and updated files. It is not printed if the
          # command raises an error.
          #
          # Commands extend their instances with this module, ahead of
          # {App::Command::Environment}, which passes on only the params the command's `#call`
          # declares.
          #
          # @api private
          # @since 3.0.0
          module Summary
            # @api private
            # @since 3.0.0
            def call(*, **opts)
              super.tap do
                stdout.puts Styles::SUCCESS["✓"] + " Generated #{generated_type} " + Styles::EMPHASIS[opts.fetch(:name)]
              end
            end

            private

            # Returns "action" for `Generate::Action`. Uses the nearest named class, so that
            # anonymous subclasses work too.
            def generated_type
              named_class = self.class.ancestors.find { |mod| mod.is_a?(Class) && mod.name }
              named_class.name.split("::").last.downcase
            end
          end
        end
      end
    end
  end
end
