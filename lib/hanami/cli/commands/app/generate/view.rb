# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.0.0
          # @api private
          class View < Command
            # TODO: make format configurable

            DEFAULT_TEMPLATE_ENGINE = "erb"
            private_constant :DEFAULT_TEMPLATE_ENGINE

            argument :name, required: true, desc: "View name"
            option :template_engine, required: false,
              values: %w[erb haml slim],
              desc: "Template engine to use (default: set in app config or erb)"
            option :force, required: false, type: :flag, default: false,
              desc: "Overwrite existing files during generation"

            example [
              %(books.index               (MyApp::Actions::Books::Index)),
              %(books.index --slice=admin (Admin::Actions::Books::Index))
            ]

            # @since 2.2.0
            # @api private
            def generator_class
              Generators::App::View
            end

            # @since 2.0.0
            # @api private
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
