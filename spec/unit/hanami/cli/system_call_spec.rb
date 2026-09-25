# frozen_string_literal: true

RSpec.describe Hanami::CLI::SystemCall do
  describe "#call" do
    subject { described_class.new }

    context "when successful" do
      it "returns a successful Result" do
        expect(subject.call("sh -c 'exit 0'")).to be_successful
      end
    end

    context "when unsuccessful" do
      it "returns an unsuccessful Result" do
        expect(subject.call("sh -c 'exit 1'")).not_to be_successful
      end
    end

    it "captures stdout and stderr" do
      expect(subject.call(%(echo "Hello, world")).stdout).to eq "Hello, world"
      expect(subject.call(%(echo "Goodbye, moon" >&2)).stderr).to eq "Goodbye, moon"
    end

    it "captures the exit code" do
      expect(subject.call("sh -c 'exit 50'").exit_code).to eq 50
    end

    it "accepts a block for stdin" do
      result = subject.call("cat") do |stdin, _stdout, _stderr, _wait_thr|
        stdin.puts "1"
        stdin.puts "2"
        stdin.puts "3"
      end

      expect(result.stdout).to eq <<~OUTPUT.strip
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

      expect(result.stdout).to include("BUNDLE_FUN_FRAMEWORK")

      # BUNDLER_SETUP is one of a handful of env vars that Bundler sets.
      expect(result.stdout).not_to include("BUNDLER_SETUP")
    end

    it "passes given env to the command" do
      result = subject.call(
        "echo $BUNDLE_GREAT_FRAMEWORK",
        env: {"BUNDLE_GREAT_FRAMEWORK" => "hanami"}
      )

      expect(result.stdout).to eq("hanami")
    end

    context "streaming to sinks" do
      let(:stdout) { StringIO.new }
      let(:stderr) { StringIO.new }

      it "writes stdout to the given sink as the command runs" do
        subject.call(%(echo "Hello, world"), stdout:)

        expect(stdout.string).to eq "Hello, world\n"
      end

      it "writes stderr to the given sink as the command runs" do
        subject.call(%(echo "Goodbye, moon" >&2), stderr:)

        expect(stderr.string).to eq "Goodbye, moon\n"
      end

      it "prepends the out prefix to each line" do
        subject.call(%(echo "Hello, world"), stdout:, out_prefix: "[admin] ")
        subject.call(%(echo "Goodbye, moon" >&2), stderr:, out_prefix: "[admin] ")

        expect(stdout.string).to eq "[admin] Hello, world\n"
        expect(stderr.string).to eq "[admin] Goodbye, moon\n"
      end

      it "does not also capture streamed output, so long-running commands do not accumulate it" do
        result = subject.call(%(echo "Hello, world"), stdout:, stderr:)

        expect(result.stdout).to be_nil
        expect(result.stderr).to be_nil
      end

      it "still reports the exit code" do
        expect(subject.call("sh -c 'exit 50'", stdout:).exit_code).to eq 50
      end

      it "captures the stream that was not given a sink" do
        result = subject.call(%(echo "Hello, world"; echo "Goodbye, moon" >&2), stdout:)

        expect(stdout.string).to eq "Hello, world\n"
        expect(result.stderr).to eq "Goodbye, moon"
      end

      it "does not exit the process, whatever the command's status" do
        expect(Kernel).not_to receive(:exit)

        expect { subject.call("sh -c 'exit 50'", stdout:) }.not_to raise_error
      end
    end

    it "concatenates the command and arguments" do
      expect(subject.call("echo", "'hello'", "'hanami'").stdout).to eq "hello hanami"
    end
  end
end
