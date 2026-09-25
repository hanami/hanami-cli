# frozen_string_literal: true

require_relative "../../system_call"

module Hanami
  module CLI
    module Commands
      module App
        # @since 2.1.0
        # @api private
        class Dev < App::Command
          # @since 2.1.0
          # @api private
          desc "Start the application in development mode"

          # @since 2.1.0
          # @api private
          def initialize(system_call: SystemCall.new)
            @system_call = system_call
          end

          # @since 2.1.0
          # @api private
          def call(**)
            bin, args = executable
            result = system_call.call(bin, *args, stdout:, stderr:)
            throw :exit, result.exit_code || 0
          end

          private

          # @since 2.1.0
          # @api private
          attr_reader :system_call

          # @since 2.1.0
          # @api private
          def executable
            [::File.join("bin", "dev")]
          end
        end
      end
    end
  end
end
