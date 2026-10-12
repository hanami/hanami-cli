# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App do
  context "when hanami-db gem is loaded" do
    it "can handle the command `hanami generate repo`" do
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-db").and_return(true)
      test_module = Module.new do
        extend Dry::CLI::Registry
        extend Hanami::CLI::Commands::App
      end
      expect(test_module.get(["generate", "repo"])).to be_found
    end
    it "can handle the command `hanami generate repository`" do
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-db").and_return(true)
      test_module = Module.new do
        extend Dry::CLI::Registry
        extend Hanami::CLI::Commands::App
      end
      expect(test_module.get(["generate", "repository"])).to be_found
    end
  end
end
