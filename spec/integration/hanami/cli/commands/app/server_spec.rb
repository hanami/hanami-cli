# frozen_string_literal: true

require "open-uri"
require "ostruct"
require "puma"

RSpec.describe Hanami::CLI::Commands::App::Server do
  it "starts rack server in the given environment" do
    host = ENV.fetch("HANAMI_CLI_TEST_HOST", "0.0.0.0")
    port = ENV.fetch("HANAMI_CLI_TEST_PORT", "2300")
    app_root = File.join(__dir__, "../../../../../fixtures/test")
    begin
      # Spawn a new process rather than forking, since fork is not available on JRuby
      pid = Process.spawn(
        "bin/hanami", "server", "--host=#{host}", "--port=#{port}", "--env=staging",
        chdir: app_root, out: File::NULL, err: File::NULL
      )

      response = open_uri("http://#{host}:#{port}/")

      expect(response).to eq("Hello, world! (staging)")
    ensure
      if pid
        Process.kill(:KILL, pid)
        Process.wait(pid)
      end
    end
  end

  # Allow time for the new process to boot (including on JRuby)
  def open_uri(uri, attempts = 30)
    URI.open(uri).read # rubocop:disable Security/Open
  rescue Errno::ECONNREFUSED
    raise if attempts.zero?

    sleep 1
    open_uri(uri, attempts - 1)
  end
end
