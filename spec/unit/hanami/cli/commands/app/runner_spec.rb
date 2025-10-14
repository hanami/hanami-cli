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
      let(:temp_file_path) { File.join(Dir.pwd, "test_script.rb") }

      before do
        File.write(temp_file_path, "puts 'Hello from file'")
      end

      after do
        File.delete(temp_file_path) if File.exist?(temp_file_path)
      end

      it "loads the file when it exists" do
        expect(Kernel).to receive(:load).with(temp_file_path).and_return(true)

        subject.call(code_or_path: temp_file_path)
      end
    end

    context "when given inline code" do
      it "evaluates simple Ruby code" do
        expect { subject.call(code_or_path: "puts 'Hello World'") }.not_to raise_error
      end

      it "clears ARGV after execution" do
        ARGV.replace(%w[arg1 arg2])

        subject.call(code_or_path: "puts 'test'")

        expect(ARGV).to be_empty
      end

      context "with syntax errors" do
        it "prints error message and exits with code 1" do
          allow(subject).to receive(:exit).and_raise(SystemExit)

          expect { subject.call(code_or_path: "puts 'unclosed string") }.to raise_error(SystemExit)

          expect(err.string).to include("Syntax error in code")
          expect(subject).to have_received(:exit).with(1)
        end
      end

      context "with name errors" do
        it "prints error message and exits with code 1" do
          allow(subject).to receive(:exit).and_raise(SystemExit)

          expect { subject.call(code_or_path: "undefined_variable") }.to raise_error(SystemExit)

          expect(err.string).to include("Name error in code")
          expect(subject).to have_received(:exit).with(1)
        end
      end

      context "with runtime errors" do
        it "prints error message and exits with code 1" do
          allow(subject).to receive(:exit).and_raise(SystemExit)

          expect { subject.call(code_or_path: "1 / 0") }.to raise_error(SystemExit)

          expect(err.string).to include("Error executing code")
          expect(subject).to have_received(:exit).with(1)
        end
      end
    end
  end

  describe "command registration" do
    it "is registered as a CLI command" do
      expect(described_class).to be < Hanami::CLI::Command
    end
  end
end
