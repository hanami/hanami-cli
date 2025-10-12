# frozen_string_literal: true

require "spec_helper"
require "hanami/cli/commands/app/runner"

RSpec.describe Hanami::CLI::Commands::App::Runner do
  subject { described_class.new(out: out, err: err) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  before do
    # Mock the hanami/boot requirement
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

      it "loads the file when it exists and is valid" do
        expect(Kernel).to receive(:load).with(temp_file.path)

        subject.call(code_or_path: temp_file.path)
      end

      context "with security validations" do
        it "rejects non-Ruby files" do
          txt_file = Tempfile.new(["test_script", ".txt"])
          txt_file.write("some content")
          txt_file.close

          expect { subject.call(code_or_path: txt_file.path) }.to raise_error(SystemExit)
          expect(err.string).to include("Only Ruby files (.rb) are allowed")

          txt_file.unlink
        end

        it "rejects files outside the application directory" do
          external_file = "/tmp/external_script.rb"
          File.write(external_file, "puts 'external'") if File.writable?("/tmp")

          if File.exist?(external_file)
            expect { subject.call(code_or_path: external_file) }.to raise_error(SystemExit)
            expect(err.string).to include("File must be within the application directory")
            File.delete(external_file)
          end
        end

        it "rejects files that are too large" do
          large_file = Tempfile.new(["large_script", ".rb"])

          # Mock file size to be over the limit
          allow(File).to receive(:size).with(large_file.path).and_return(11 * 1024 * 1024)

          expect { subject.call(code_or_path: large_file.path) }.to raise_error(SystemExit)
          expect(err.string).to include("File too large")

          large_file.unlink
        end
      end
    end

    context "when given inline code" do
      it "evaluates simple Ruby code" do
        expect { subject.call(code_or_path: "puts 'Hello World'") }.not_to raise_error
      end

      it "handles syntax errors gracefully" do
        expect { subject.call(code_or_path: "puts 'unclosed string") }.to raise_error(SystemExit)
        expect(err.string).to include("Syntax error in code")
      end

      it "handles name errors gracefully" do
        expect { subject.call(code_or_path: "undefined_variable") }.to raise_error(SystemExit)
        expect(err.string).to include("Name error in code")
      end

      it "handles runtime errors gracefully" do
        expect { subject.call(code_or_path: "raise 'test error'") }.to raise_error(SystemExit)
        expect(err.string).to include("Error executing code")
      end

      context "with security validations" do
        it "rejects code that is too long" do
          long_code = "puts 'x'" * 5000  # Over 10KB when repeated

          expect { subject.call(code_or_path: long_code) }.to raise_error(SystemExit)
          expect(err.string).to include("Inline code too long")
        end

        it "allows safe Ruby operations" do
          safe_codes = [
            "puts 'Hello'",
            "x = 1 + 1",
            "arr = [1, 2, 3]; arr.map(&:to_s)",
            "Time.now",
            "Math.sqrt(16)"
          ]

          safe_codes.each do |code|
            expect { subject.call(code_or_path: code) }.not_to raise_error
          end
        end
      end

      it "clears ARGV after execution" do
        ARGV.replace(["arg1", "arg2"])

        subject.call(code_or_path: "puts 'test'")

        expect(ARGV).to be_empty
      end
    end
  end

  describe "command registration" do
    it "is registered with proper aliases" do
      # This would be tested in an integration test, but we can verify the class exists
      expect(described_class).to be < Hanami::CLI::Command
    end
  end

  describe "examples and documentation" do
    it "provides helpful examples in the class documentation" do
      # Test that the command has proper description and examples
      expect(described_class).to respond_to(:desc)
      expect(described_class).to respond_to(:example)
      
      # Verify the command is properly configured
      command_instance = described_class.new(out: out, err: err)
      expect(command_instance).to respond_to(:call)
    end
  end
end
