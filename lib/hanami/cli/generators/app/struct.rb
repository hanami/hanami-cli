# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Struct
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, stdout: $stdout)
            @fs = fs
            @inflector = inflector
            @stdout = stdout
          end

          # @since 2.2.0
          # @api private
          def call(key:, namespace:, base_path:, force: false)
            create_app_base_struct_if_missing
            create_slice_base_struct_if_missing(namespace:, base_path:) unless namespace == Hanami.app.namespace

            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              key: key,
              namespace: namespace,
              base_path: base_path,
              extra_namespace: "Structs",
              parent_class_name: "#{inflector.camelize(namespace)}::DB::Struct"
            ).create(force:)
          end

          private

          attr_reader :fs, :inflector, :stdout

          def create_app_base_struct_if_missing
            return if fs.exist?(fs.join(APP_DIR, "db", "struct.rb"))

            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              namespace: Hanami.app.namespace,
              key: "db.struct",
              base_path: APP_DIR,
              parent_class_name: "Hanami::DB::Struct",
              requires: ["hanami/db/struct"]
            ).create
          end

          def create_slice_base_struct_if_missing(namespace:, base_path:)
            return if fs.exist?(fs.join(base_path, "db", "struct.rb"))

            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              namespace: namespace,
              key: "db.struct",
              base_path: base_path,
              parent_class_name: "#{Hanami.app.namespace}::DB::Struct"
            ).create
          end
        end
      end
    end
  end
end
