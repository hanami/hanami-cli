# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Dev do
  subject { described_class.new(system_call: system_call, stdout: out, stderr: err) }

  let(:system_call) { instance_double(Hanami::CLI::SystemCall) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def result(exit_code)
    Hanami::CLI::SystemCall::Result.new(exit_code: exit_code, stdout: nil, stderr: nil)
  end

  context "#call" do
    it "invokes external command to start Procfile based session, streaming its output" do
      expect(system_call).to receive(:call)
        .with("bin/dev", stdout: subject.stdout, stderr: subject.stderr)
        .and_return(result(0))

      expect_exit_code(0) { subject.call }
    end

    it "exits with the command's exit code" do
      allow(system_call).to receive(:call).and_return(result(2))

      expect_exit_code(2) { subject.call }
    end
  end
end
