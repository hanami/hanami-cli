# frozen_string_literal: true

require "hanami/cli/commands/app/db/utils/database"

RSpec.describe Hanami::CLI::Commands::App::DB::Utils::Database do
  describe ".database_class" do
    {
      "sqlite://db/app.sqlite3" => "Sqlite",
      "jdbc:sqlite:db/app.sqlite3" => "Sqlite",
      "postgres://localhost/app" => "Postgres",
      "postgresql://localhost/app" => "Postgres",
      "jdbc:postgresql://localhost/app" => "Postgres",
      "mysql://localhost/app" => "Mysql",
      "mysql2://localhost/app" => "Mysql",
      "jdbc:mysql://localhost/app" => "Mysql"
    }.each do |url, class_name|
      it "returns #{class_name} for #{url}" do
        expect(described_class.database_class(url).name).to eq "Hanami::CLI::Commands::App::DB::Utils::#{class_name}"
      end
    end

    it "raises an error for unsupported schemes, without including the URL's credentials" do
      expect { described_class.database_class("oracle://user:secret@localhost/app") }
        .to raise_error(Hanami::CLI::UnsupportedDatabaseSchemeError, "`oracle' is not a supported db scheme")
    end

    it "includes the JDBC subprotocol in the error for unsupported JDBC URLs" do
      expect { described_class.database_class("jdbc:sqlserver://localhost;user=sa;password=secret") }
        .to raise_error(Hanami::CLI::UnsupportedDatabaseSchemeError, "`jdbc:sqlserver' is not a supported db scheme")
    end

    it "raises an error for unsupported JDBC subprotocols" do
      expect { described_class.database_class("jdbc:postgres://localhost/app") }
        .to raise_error(Hanami::CLI::UnsupportedDatabaseSchemeError, "`jdbc:postgres' is not a supported db scheme")
    end

    it "raises an error for URLs that cannot be parsed, without including the URL's credentials" do
      expect { described_class.database_class("postgres://user:se cret@localhost/app") }
        .to raise_error(Hanami::CLI::InvalidDatabaseURLError) { |error|
          expect(error.message).to start_with "`postgres' database URL could not be parsed"
          expect(error.message).not_to include "cret"
          expect(error.cause).to be_nil
        }
    end

    it "raises an error for URLs without a scheme" do
      expect { described_class.database_class("db/app.sqlite3") }
        .to raise_error(Hanami::CLI::UnsupportedDatabaseSchemeError, "`(none)' is not a supported db scheme")
    end
  end
end
