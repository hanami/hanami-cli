# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module App
        # @api private
        class Provider
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          def call(key:, namespace:, base_path:, force: false, **_opts)
            name = inflector.underscore(key)

            registrar =
              if base_path == "app"
                "Hanami.app"
              else
                "#{inflector.camelize(namespace)}::Slice"
              end

            base_path = nil if base_path == "app" # Providers live in config/, not app/
            path = fs.join(*[base_path, "config", "providers", "#{name}.rb"].compact)

            fs.create(path, file_contents(registrar, name), force:)
          end

          private

          attr_reader :fs, :inflector, :out

          def file_contents(registrar, name)
            <<~RUBY
              # frozen_string_literal: true

              #{registrar}.register_provider :#{name} do
                # Define your provider here.
                #
                # See https://hanakai.org/learn/hanami/app/providers for details.

                start do
                  # Set up and register the provider's components.
                end
              end
            RUBY
          end
        end
      end
    end
  end
end
