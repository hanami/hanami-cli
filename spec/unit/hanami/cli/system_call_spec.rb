# frozen_string_literal: true

RSpec.describe Hanami::CLI::SystemCall do
  describe "#call" do
    subject { described_class.new }

    context "when successful" do
      it "returns a successful Result" do
        expect(subject.call("return 0")).to be_successful
      end
    end

    context "when unsuccessful" do
      it "returns an unsuccessful Result" do
        expect(subject.call("return 1")).not_to be_successful
      end
    end

    it "captures stdout and stderr" do
      expect(subject.call(%(echo "Hello, world")).out).to eq "Hello, world"
      expect(subject.call(%(echo "Goodbye, moon" >&2)).err).to eq "Goodbye, moon"
    end

    it "captures the exit code" do
      expect(subject.call("return 50").exit_code).to eq 50
    end

    it "accepts a block for stdin" do
      result = subject.call("cat") do |stdin, _stdout, _stderr, _wait_thr|
        stdin.puts "1"
        stdin.puts "2"
        stdin.puts "3"
      end

      expect(result.out).to eq <<~OUTPUT.strip
        1
        2
        3
      OUTPUT
    end

    it "strips bundler-added environment variables preserving pre-existing ones" do
      Bundler.original_env.dup
        .merge("BUNDLE_FUN_FRAMEWORK" => "hanami")
        .then { |env| allow(Bundler).to receive(:original_env).and_return(env) }

      result = subject.call("cat") do |stdin, _stdout, _stderr, _wait_thr|
        stdin.puts ENV.keys.sort
      end

      expect(result.out).to include("BUNDLE_FUN_FRAMEWORK")

      # BUNDLER_SETUP is one of a handful of env vars that Bundler sets.
      expect(result.out).not_to include("BUNDLER_SETUP")
    end

    it "passes given env to the command" do
      result = subject.call(
        "echo $BUNDLE_GREAT_FRAMEWORK",
        env: {"BUNDLE_GREAT_FRAMEWORK" => "hanami"}
      )

      expect(result.out).to eq("hanami")
    end

    it "concatenates the command and arguments" do
      expect(subject.call("echo", "'hello'", "'hanami'").out).to eq "hello hanami"
    end
  end
end
