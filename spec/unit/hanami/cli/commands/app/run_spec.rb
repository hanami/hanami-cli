# frozen_string_literal: true

require "spec_helper"
require "hanami/cli/commands/app/run"

RSpec.describe Hanami::CLI::Commands::App::Run do
  subject { described_class.new(out: out, err: err, command_exit: command_exit) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:command_exit) { double(:command_exit) }

  before do
    # Mock the hanami/prepare requirement
    allow(subject).to receive(:require).with("hanami/prepare")

    allow(command_exit).to receive(:call)
  end

  describe "#call" do
    context "when given a file path" do
      let(:temp_file_path) { File.join(Dir.pwd, "test_script.rb") }

      before do
        File.write(temp_file_path, "puts 'Hello from file'")
      end

      after do
        FileUtils.rm_f(temp_file_path)
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

      context "with syntax errors" do
        it "prints error message and exits with code 1" do
          subject.call(code_or_path: "puts 'unclosed string")

          expect(err.string).to include("Syntax error in code")
          expect(command_exit).to have_received(:call).with(1)
        end
      end

      context "with name errors" do
        it "prints error message and exits with code 1" do
          subject.call(code_or_path: "undefined_variable")

          expect(err.string).to include("Name error in code")
          expect(command_exit).to have_received(:call).with(1)
        end
      end

      context "with runtime errors" do
        it "prints error message and exits with code 1" do
          subject.call(code_or_path: "1 / 0")

          expect(err.string).to include("Error executing code")
          expect(command_exit).to have_received(:call).with(1)
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
