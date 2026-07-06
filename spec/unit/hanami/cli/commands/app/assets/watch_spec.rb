# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Watch, "#call", :app_integration do
  subject(:command) {
    described_class.new(
      system_call: interactive_system_call,
      out: out
    )
  }

  let(:interactive_system_call) { instance_double(Hanami::CLI::InteractiveSystemCall) }

  let(:out) { StringIO.new }
  let(:output) {
    out.rewind
    out.read
  }

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/assets.js", ""

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end


  describe "assets in app" do
    describe "assets dir present" do
      def before_prepare
        write "app/assets/.keep", ""
      end

      it "watches the app assets" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          "config/assets.js",
          "--",
          "--path=app",
          "--dest=public/assets",
          "--watch",
          {out_prefix: "[test_app] "}
        )

        command.call
      end
    end

    describe "assets dir absent" do
      it "does not watch app assets" do
        expect(interactive_system_call).not_to receive(:call)

        command.call

        expect(output).to eq "No assets found.\n"
      end
    end
  end

  describe "assets in slice" do
    describe "assets dir present" do
      def before_prepare
        write "slices/admin/assets/.keep", ""
      end

      it "watches the slice assets" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          "config/assets.js",
          "--",
          "--path=slices/admin",
          "--dest=public/assets/_admin",
          "--watch",
          {out_prefix: "[admin] "}
        )

        command.call
      end
    end

    describe "slice assets config file" do
      def before_prepare
        write "slices/admin/config/assets.js", ""
        write "slices/admin/assets/.keep", ""
      end

      it "watches the slice assets using the slice's assets config" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          "slices/admin/config/assets.js",
          "--",
          "--path=slices/admin",
          "--dest=public/assets/_admin",
          "--watch",
          {out_prefix: "[admin] "}
        )

        command.call
      end
    end

    describe "assets dir absent" do
      def before_prepare
        write "slices/admin/.keep", ""
      end

      it "does not watch app assets" do
        expect(interactive_system_call).not_to receive(:call)

        command.call
      end
    end
  end

  describe "assets present in multiple slices" do
    def before_prepare
      write "slices/admin/assets/.keep", ""
      write "slices/main/assets/.keep", ""
    end

    it "watches the assets for each slice" do
      expect(interactive_system_call).to receive(:call).with(
        "node",
        "config/assets.js",
        "--",
        "--path=slices/admin",
        "--dest=public/assets/_admin",
        "--watch",
        {out_prefix: "[admin] "}
      )

      expect(interactive_system_call).to receive(:call).with(
        "node",
        "config/assets.js",
        "--",
        "--path=slices/main",
        "--dest=public/assets/_main",
        "--watch",
        {out_prefix: "[main] "}
      )

      command.call
    end
  end
end
