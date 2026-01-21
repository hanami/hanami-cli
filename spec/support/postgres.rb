# frozen_string_literal: true

require "open3"
require "uri"

POSTGRES_BASE_DB_NAME = "hanami_cli_test"
POSTGRES_BASE_URL = if RUBY_ENGINE == "jruby"
                      ENV.fetch("POSTGRES_BASE_URL",
                                "jdbc:postgres://postgres:password@localhost:5433/#{POSTGRES_BASE_DB_NAME}")
                    else
                      ENV.fetch("POSTGRES_BASE_URL",
                                "postgres://postgres:password@localhost:5433/#{POSTGRES_BASE_DB_NAME}")
                    end
POSTGRES_BASE_URI = URI(POSTGRES_BASE_URL)

RSpec.configure do |config|
  # Drop all databases with names starting with POSTGRES_URL_BASE
  config.after :each, :postgres do
    cmd_env = {
      "PGHOST" => POSTGRES_BASE_URI.host,
      "PGPORT" => POSTGRES_BASE_URI.port.to_s,
      "PGUSER" => POSTGRES_BASE_URI.user,
      "PGPASSWORD" => POSTGRES_BASE_URI.password
    }

    psql_list, _status = Open3.capture2(cmd_env, "psql -t -A -c '\\l #{POSTGRES_BASE_DB_NAME}*'")

    test_databases = psql_list.split("\n").map { _1.split("|").first }
    test_databases.each do |database|
      system(cmd_env, "dropdb --force #{database}")
    end
  end
end
