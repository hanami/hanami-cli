# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @api private
          class Provider < Command
            argument :name, required: true, desc: "Provider name"
            option :force, required: false, type: :flag, default: false,
              desc: "Overwrite existing files during generation"

            example [
              %(mailer                (config/providers/mailer.rb)),
              %(mailer --slice=admin  (slices/admin/config/providers/mailer.rb))
            ]

            def generator_class
              Generators::App::Provider
            end
          end
        end
      end
    end
  end
end
