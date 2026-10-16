# frozen_string_literal: true

require "hanami"

RSpec.describe "file conflict handling", :app do
  subject(:cmd) { Hanami::CLI::Commands::App::Generate::View.new(fs:, stdout:, stderr:) }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout:) }

  context "when file to be generated already exists" do
    it "exits with error" do
      subject.call(name: "users.new")

      file_path = "app/views/users/new.rb"

      expect do
        subject.call(name: "users.new")
      end.to raise_error Hanami::CLI::FileAlreadyExistsError, Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
    end

    it "prints the error and exits with 1 when run by the CLI" do
      subject.call(name: "users.new")

      file_path = "app/views/users/new.rb"
      exit_code = nil

      Dry::CLI.new(cmd).call(arguments: ["users.new"], stdout:, stderr:, exit: ->(code) { exit_code = code })

      expect(exit_code).to eq 1
      expect(stderr.string.chomp).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
    end
  end
end
