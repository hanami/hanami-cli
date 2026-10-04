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

      def postgres_url(db_suffix)
        url = "#{POSTGRES_BASE_URL}#{db_suffix}"
        jruby? ? jdbc_url(url, scheme: "postgresql") : url
      end

      def mysql_url(db_suffix)
        url = "#{MYSQL_BASE_URL}#{db_suffix}"
        jruby? ? jdbc_url(url, scheme: "mysql") : url
      end

      def jdbc_url(url, scheme:)
        uri = URI(url)
        # JDBC drivers expect the user and password as query params, not in the userinfo
        query = URI.encode_www_form({user: uri.user, password: uri.password}.compact)
        "jdbc:#{scheme}://#{uri.host}:#{uri.port}#{uri.path}?#{query}"
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
