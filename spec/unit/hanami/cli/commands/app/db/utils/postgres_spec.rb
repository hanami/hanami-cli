# frozen_string_literal: true

require "hanami/cli/commands/app/db/utils/postgres"

RSpec.describe Hanami::CLI::Commands::App::DB::Utils::Postgres do
  subject(:database) {
    described_class.new(
      slice: Object.new,
      gateway_name: :default,
      system_call: Object.new
    )
  }

  let(:database_uri) {
    Struct.new(:host, :port, :user, :password, :query).new(host, port, user, password, query)
  }

  before do
    allow(database).to receive(:database_uri).and_return(database_uri)
  end

  describe "#cli_env_vars" do
    let(:host) { "localhost" }
    let(:port) { 5433 }
    let(:user) { "hanami" }
    let(:password) { "secret" }
    let(:query) { nil }

    it "uses connection values from the database URL" do
      expect(database.send(:cli_env_vars)).to eq(
        "PGHOST" => "localhost",
        "PGPORT" => "5433",
        "PGUSER" => "hanami",
        "PGPASSWORD" => "secret"
      )
    end

    context "when the user and password are percent-encoded" do
      let(:user) { "app%40corp" }
      let(:password) { "p%40ss%3Aw%2F0rd+%25" }

      it "decodes them" do
        expect(database.send(:cli_env_vars)).to include(
          "PGUSER" => "app@corp",
          "PGPASSWORD" => "p@ss:w/0rd+%"
        )
      end
    end

    context "when the user and password are percent-encoded query params" do
      let(:user) { nil }
      let(:password) { nil }
      let(:query) { "user=app%40corp&password=p%40ss%3Aw%2F0rd%25" }

      it "decodes them" do
        expect(database.send(:cli_env_vars)).to include(
          "PGUSER" => "app@corp",
          "PGPASSWORD" => "p@ss:w/0rd%"
        )
      end
    end

    context "when the database URL has blank values" do
      let(:host) { "" }
      let(:port) { nil }
      let(:user) { "" }
      let(:password) { "" }

      it "does not override libpq environment variables" do
        expect(database.send(:cli_env_vars)).to eq({})
      end
    end
  end
end
