# frozen_string_literal: true

module RSpec
  module Support
    module Helpers
      def expect_exit_code(expected = 0)
        actual = catch(:exit) do
          yield
          0
        end
        expect(actual).to eq(expected)
        actual
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Helpers
end
