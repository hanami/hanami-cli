# frozen_string_literal: true

require "hanami"

RSpec.describe "file conflict handling", :app do
  subject(:cmd) { Hanami::CLI::Commands::App::Generate::View.new(fs:, stdout:, stderr:) }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout:) }

  def error_output = stderr.string.chomp

  context "when file to be generated already exists" do
    it "exits with error" do
      subject.call(name: "users.new")

      file_path = "app/views/users/new.rb"

      expect do
        subject.call(name: "users.new")
      end.to raise_error SystemExit do |exception|
        expect(exception.status).to eq 1
        expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
      end
    end
  end
end
