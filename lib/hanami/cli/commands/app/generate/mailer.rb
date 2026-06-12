# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @api private
          class Mailer < Command
            DEFAULT_TEMPLATE_ENGINE = "erb"

            argument :name, required: true, desc: "Mailer name"
            option :template_engine, required: false,
              values: %w[erb haml slim],
              desc: "Template engine to use (default: set in app config or erb)"
            option :force, required: false, type: :flag, default: false,
              desc: "Overwrite existing files during generation"

            example [
              %(welcome               (MyApp::Mailers::Welcome)),
              %(welcome --slice=admin (Admin::Mailers::Welcome))
            ]

            def generator_class
              Generators::App::Mailer
            end

            def call(name:, slice: nil, template_engine: nil, force: false, **opts)
              super(name:, slice:, template_engine: template_engine || default_template_engine, force: force)
            end

            private

            def default_template_engine
              if Hanami.bundled?("hanami-view") && app.config.views.respond_to?(:default_template_engine)
                app.config.views.default_template_engine
              else
                DEFAULT_TEMPLATE_ENGINE
              end
            end
          end
        end
      end
    end
  end
end
