# frozen_string_literal: true

RSpec.describe Hanami::CLI::InteractiveSystemCall do
  let(:out)        { StringIO.new }
  let(:err)        { StringIO.new }
  let(:stdout)     { out.tap(&:rewind).read }
  let(:stderr)     { err.tap(&:rewind).read }

  let(:exit_after) { false }
  subject          { described_class.new(out:, err:, exit_after:) }

  after(:each) do
    out.close
    err.close
  end

  describe "#call" do
    context "when exit_after: true" do
      let(:exit_after) { true }

      it "exits with the exit code" do
        allow(Kernel).to receive(:exit).with(50).and_raise(SystemExit)
        expect { subject.call("return 50") }.to raise_error(SystemExit)
      end
    end

    context "when exit_after: false" do
      it "does not exit" do
        expect(Kernel).not_to receive(:exit)
        expect { subject.call("return 0") }.not_to raise_error
      end
    end

    it "writes stdout to the passed sink" do
      subject.call(%(echo "Hello, world"))
      expect(stdout).to eq "Hello, world\n"
    end

    it "prepends the out prefix to stdout content" do
      subject.call(%(echo "Hello, world"), out_prefix: "[admin] ")
      expect(stdout).to eq "[admin] Hello, world\n"
    end

    it "writes stderr to the passed sink" do
      subject.call(%(echo "Goodbye, moon" >&2))
      expect(stderr).to eq "Goodbye, moon\n"
    end

    it "prepends the out prefix to stderr content" do
      subject.call(%(echo "Goodbye, moon" >&2), out_prefix: "[admin] ")
      expect(stderr).to eq "[admin] Goodbye, moon\n"
    end

    it "strips bundler-added environment variables preserving pre-existing ones" do
      Bundler.original_env.dup
        .merge("BUNDLE_FUN_FRAMEWORK" => "hanami")
        .then { |env| allow(Bundler).to receive(:original_env).and_return(env) }

      subject.call("env")

      # BUNDLER_SETUP is one of a handful of env vars that Bundler sets.
      expect(stdout).to include("BUNDLE_FUN_FRAMEWORK")
        .and exclude("BUNDLER_SETUP")
    end

    it "passes given env to the command" do
      subject.call(
        "echo $BUNDLE_GREAT_FRAMEWORK",
        env: {"BUNDLE_GREAT_FRAMEWORK" => "hanami"}
      )

      expect(stdout).to eq("hanami\n")
    end

    it "concatenates the command and arguments" do
      subject.call("echo", "'hello'", "'hanami'")
      expect(stdout).to eq "hello hanami\n"
    end
  end
end
