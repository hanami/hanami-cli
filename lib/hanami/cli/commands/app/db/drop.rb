# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Drop < DB::Command
            desc "Delete databases"

            option :gateway, required: false, desc: "Use database for gateway"

            def call(app: false, slice: nil, gateway: nil, **)
              exit_codes = []

              databases(app: app, slice: slice, gateway: gateway).each do |database|
                result = database.exec_drop_command
                exit_codes << result.exit_code if result.respond_to?(:exit_code)

                if result == true || result.successful?
                  puts "=> database #{database.name} dropped"
                else
                  puts "=> failed to drop database #{database.name}"
                  puts "#{result.stderr}\n"
                end
              end

              exit_codes.each do |code|
                throw(:exit, code) if code > 0
              end

              re_run_development_command_in_test
            end
          end
        end
      end
    end
  end
end
