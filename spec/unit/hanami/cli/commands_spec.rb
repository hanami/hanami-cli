# frozen_string_literal: true

RSpec.describe Hanami::CLI do
  describe ".within_hanami_app?" do
    context "when hanami gem is available" do
      before do
        allow(Hanami).to receive(:app_path).and_return("/some/path")
      end

      it "returns true when Hanami.app_path is truthy" do
        expect(described_class.within_hanami_app?).to be true
      end
    end

    context "when hanami gem is not installed" do
      before do
        allow(described_class).to receive(:require).with("hanami").and_raise(
          LoadError.new("cannot load such file -- hanami").tap { |e| e.instance_variable_set(:@path, "hanami") }
        )
      end

      it "falls back to checking for config/app.rb" do
        allow(File).to receive(:exist?).with("config/app.rb").and_return(true)
        expect(described_class.within_hanami_app?).to be true

        allow(File).to receive(:exist?).with("config/app.rb").and_return(false)
        expect(described_class.within_hanami_app?).to be false
      end
    end

    context "when gem version conflict occurs" do
      before do
        # Simulate a Gem::LoadError with nil path (like bigdecimal version conflict)
        gem_error = Gem::LoadError.new("can't activate bigdecimal-4.0.1, already activated bigdecimal-3.3.1")
        gem_error.instance_variable_set(:@path, nil)

        allow(described_class).to receive(:require).with("hanami").and_raise(gem_error)
      end

      it "falls back to checking for config/app.rb" do
        allow(File).to receive(:exist?).with("config/app.rb").and_return(true)
        expect(described_class.within_hanami_app?).to be true

        allow(File).to receive(:exist?).with("config/app.rb").and_return(false)
        expect(described_class.within_hanami_app?).to be false
      end
    end

    context "when other LoadError occurs during hanami loading" do
      before do
        other_error = LoadError.new("cannot load such file -- some_other_gem")
        other_error.instance_variable_set(:@path, "some_other_gem")

        allow(described_class).to receive(:require).with("hanami").and_raise(other_error)
      end

      it "re-raises the exception" do
        expect { described_class.within_hanami_app? }.to raise_error(LoadError, /some_other_gem/)
      end
    end
  end
end
