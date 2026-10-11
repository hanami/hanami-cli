# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Install do
  subject { described_class.new(fs:, bundler:, stdout:) }

  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout:) }
  let(:bundler) { Hanami::CLI::Bundler.new(fs:) }
  let(:stdout) { StringIO.new }

  describe "#call" do
    it "installs third-party plugins" do
      expect(bundler).to receive(:install!)
        .exactly(1).time
        .and_return(true)

      subject.call

      stdout.rewind
      expect(stdout.read.chomp).to eq("")
    end
  end
end
