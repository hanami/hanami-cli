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

            argument :name, required: true, desc: "View name"
            option :template_engine, required: false,
                                     desc: "Template engine to use",
                                     values: %w[erb haml slim],
                                     default: "erb"

            example [
              %(books.index               (MyApp::Actions::Books::Index)),
              %(books.index --slice=admin (Admin::Actions::Books::Index)),
            ]

            # @since 2.2.0
            # @api private
            def generator_class
              Generators::App::View
            end
          end
        end
      end
    end
  end
end
