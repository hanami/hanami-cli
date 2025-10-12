# frozen_string_literal: true

require "spec_helper"
require "hanami/cli/commands/app/runner"

RSpec.describe Hanami::CLI::Commands::App::Runner do
  subject { described_class.new(out: out, err: err) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  before do
    # Mock the hanami/prepare requirement
    allow(subject).to receive(:require).with("hanami/prepare")
    # Clear ARGV for clean tests
    ARGV.clear
  end

  describe "#call" do
    context "when given a file path" do
      let(:temp_file) { Tempfile.new(["test_script", ".rb"]) }

      before do
        temp_file.write("puts 'Hello from file'")
        temp_file.close
      end

      after do
        temp_file.unlink
      end

      it "loads the file when it exists" do
        expect(Kernel).to receive(:load).with(temp_file.path)

        subject.call(code_or_path: temp_file.path)
      end
    end

    context "when given inline code" do
      it "evaluates simple Ruby code" do
        expect { subject.call(code_or_path: "puts 'Hello World'") }.not_to raise_error
      end

      it "clears ARGV after execution" do
        ARGV.replace(["arg1", "arg2"])

        subject.call(code_or_path: "puts 'test'")

        expect(ARGV).to be_empty
      end
    end
  end

  describe "command registration" do
    it "is registered as a CLI command" do
      expect(described_class).to be < Hanami::CLI::Command
    end
  end
end
