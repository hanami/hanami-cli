# frozen_string_literal: true

require "fileutils"
require "pathname"
require "shellwords"
require "hanami/cli/commands/app/db/utils/database"
require "hanami/cli/commands/app/db/utils/sqlite"
require "hanami/cli/commands/app/db/utils/postgres"
require "hanami/cli/commands/app/db/utils/mysql"

RSpec.describe "Database utils path quoting" do
  subject(:database) {
    database_class.new(slice: slice, gateway_name: :default, system_call: system_call)
  }

  let(:database_class) { Hanami::CLI::Commands::App::DB::Utils::Database }
  let(:database_url) { "sqlite://db/app.sqlite3" }
  let(:system_call) { instance_double(Hanami::CLI::SystemCall) }
  let(:slice) { double(:slice, app: double(:app, root: app_root), root: app_root) }
  let(:app_root) { Pathname.new("/apps/My App") }

  before do
    allow(database).to receive(:database_url).and_return(database_url)
  end

  # Run the block and return the command string handed to the shell
  def command_from(&block)
    commands = []
    allow(system_call).to receive(:call) { |command, **_options| commands << command }

    block.call

    commands.last
  end

  # Arguments the shell would pass to the client once the command is unquoted
  def shell_arguments(command)
    Shellwords.split(command)
  end

  describe "#quoted_path" do
    subject(:quoted) { database.send(:quoted_path, path) }

    {
      "spaces" => "/apps/My App/db/app.sqlite3",
      "single quotes" => %(/apps/Hanami's App/db/app.sqlite3),
      "shell metacharacters" => %(/apps/$HOME `id` "x"/db/app.sqlite3),
      "non-ASCII characters" => "/apps/Café 花見/db/app.sqlite3"
    }.each do |description, raw_path|
      context "with #{description} in the path" do
        let(:path) { raw_path }

        it "produces a single word the shell reads back verbatim" do
          expect(shell_arguments(quoted)).to eq([path])
        end
      end
    end
  end

  context "with SQLite" do
    let(:database_class) { Hanami::CLI::Commands::App::DB::Utils::Sqlite }
    let(:database_url) { "sqlite://db/app.sqlite3" }

    let(:database_path) { "/apps/My App/db/app.sqlite3" }
    let(:structure_file) { "/apps/My App/config/db/structure.sql" }

    it "quotes the database path when creating" do
      allow(FileUtils).to receive(:mkdir_p)

      expect(shell_arguments(command_from { database.exec_create_command }))
        .to include(database_path)
    end

    it "quotes the database path when dumping" do
      expect(shell_arguments(command_from { database.exec_dump_command }))
        .to include(database_path)
    end

    it "quotes the database and structure file paths when loading" do
      expect(shell_arguments(command_from { database.exec_load_command }))
        .to include(database_path, structure_file)
    end
  end

  context "with PostgreSQL" do
    let(:database_class) { Hanami::CLI::Commands::App::DB::Utils::Postgres }
    let(:database_url) { "postgres://localhost/test" }

    it "quotes the structure file path when loading" do
      expect(shell_arguments(command_from { database.exec_load_command }))
        .to include("/apps/My App/config/db/structure.sql")
    end
  end

  context "with MySQL" do
    let(:database_class) { Hanami::CLI::Commands::App::DB::Utils::Mysql }
    let(:database_url) { "mysql2://localhost/test" }

    it "quotes the structure file path when loading" do
      expect(shell_arguments(command_from { database.exec_load_command }))
        .to include("/apps/My App/config/db/structure.sql")
    end
  end
end
