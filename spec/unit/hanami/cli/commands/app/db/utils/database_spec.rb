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
        .to raise_error(RuntimeError, "oracle is not a supported db scheme")
    end
  end
end
