# frozen_string_literal: true

require "dry/files"
require_relative "../constants"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @api private
        class Mailer
          TEMPLATES_FOLDER = "templates/mailers"
          DEFAULT_TEMPLATE_ENGINE = "erb"

          def initialize(fs:, inflector:, stdout: $stdout)
            @fs = fs
            @inflector = inflector
            @stdout = stdout
          end

          def call(key:, namespace:, base_path:, template_engine: DEFAULT_TEMPLATE_ENGINE, force: false, **)
            mailer_class_file(key:, namespace:, base_path:).then do |mailer_class|
              mailer_class.create(force:)
              mailer_class_name = mailer_class.fully_qualified_name
              create_template_files(key:, base_path:, mailer_class_name:, template_engine:, force:)
            end
          end

          private

          attr_reader :fs, :inflector, :stdout

          def mailer_class_file(key:, namespace:, base_path:)
            RubyClassFile.new(
              fs:, inflector:,
              namespace:,
              key:,
              base_path:,
              parent_class_name: "#{inflector.camelize(namespace)}::Mailer",
              extra_namespace: "Mailers"
            )
          end

          def create_template_files(key:, base_path:, mailer_class_name:, template_engine:, force:)
            key_parts = key.split(KEY_SEPARATOR)
            class_name_from_key = key_parts.pop # takes last segment as the class name
            module_names_from_key = key_parts # the rest of the segments are the module names

            html_path = template_path(base_path, module_names_from_key, class_name_from_key, "html", template_engine)
            fs.create(html_path, html_body(mailer_class_name, template_engine), force:)

            text_path = template_path(base_path, module_names_from_key, class_name_from_key, "text", "erb")
            fs.create(text_path, text_body(mailer_class_name), force:)
          end

          def template_path(base_path, module_names, name, format, engine)
            fs.join(
              base_path,
              TEMPLATES_FOLDER,
              module_names,
              "#{name}.#{format}.#{engine}"
            )
          end

          def html_body(mailer_class_name, engine)
            case engine
            when "erb" then "<h1>#{mailer_class_name}</h1>\n"
            when "haml" then "%h1 #{mailer_class_name}\n"
            when "slim" then "h1 #{mailer_class_name}\n"
            end
          end

          def text_body(mailer_class_name)
            "#{mailer_class_name}\n"
          end
        end
      end
    end
  end
end
