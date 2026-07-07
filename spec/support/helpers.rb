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

      def sqlite_url(url, dir: nil)
        url = sqlite_db_name(url, dir:)
        if jruby?
          # We need to ensure that the parent directory for the database exists, because JDBC driver
          # won't create it
          base_dir = File.dirname(url)
          FileUtils.mkdir_p(base_dir)
          "jdbc:sqlite:#{url}"
        else
          "sqlite://#{url}"
        end
      end

      def sqlite_db_name(url, dir: nil)
        # JDBC driver does not use Dir.current for building the path, so we need to construct
        # the correct path ourselves
        jruby? && dir ? File.join(dir, url) : url
      end

      def jruby?
        RUBY_ENGINE == "jruby"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Helpers
end
