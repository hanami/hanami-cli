# frozen_string_literal: true

RSpec.describe Hanami::Console::Context do
  subject(:console_env) { Object.new.extend(described_class.new(app)) }

  after { Hanami::Console::Plugins::UnbootedSliceWarnings.deactivate }

  # Real objects rather than doubles: the code under test asks `respond_to?(:reload)`, which a
  # double cannot answer honestly.
  def build_app(code_reloading:, reloadable:)
    config = Class.new do
      def initialize(code_reloading) = @code_reloading = code_reloading
      attr_reader :code_reloading

      def console = Struct.new(:extensions).new([])
    end.new(code_reloading)

    klass = Class.new do
      attr_reader :config, :reloads, :slices

      def initialize(config)
        @config = config
        @reloads = 0
        # A hash answers `keys` and `[]`, which is all the slice readers use.
        @slices = {}
      end
    end

    klass.define_method(:reload) { @reloads += 1 } if reloadable

    klass.new(config)
  end

  describe "#reload" do
    context "when the app can reload in place" do
      let(:app) { build_app(code_reloading: true, reloadable: true) }

      it "reloads the app and reports how long it took" do
        expect { console_env.reload }.to output(/Reloading\.\.\. done \(\d+ms\)/).to_stdout

        expect(app.reloads).to eq(1)
      end

      it "does not replace the process, so the session survives" do
        expect(Kernel).not_to receive(:exec)

        expect { console_env.reload }.to output.to_stdout
      end

      it "is also available as `reload!`, which Rails users reach for" do
        expect { console_env.reload! }.to output(/Reloading\.\.\. done/).to_stdout

        expect(app.reloads).to eq(1)
      end

      it "adds and removes slice readers to match the slices after the reload" do
        app.slices[:shop] = :shop_slice

        def app.reload = @slices = {admin: :admin_slice}

        expect(console_env.shop).to eq(:shop_slice)

        expect { console_env.reload }.to output.to_stdout

        expect(console_env.admin).to eq(:admin_slice)
        expect(console_env).not_to respond_to(:shop)
      end
    end

    context "when reloading raises" do
      let(:app) { build_app(code_reloading: true, reloadable: true) }

      before do
        def app.reload = raise(SyntaxError, "unexpected end-of-input")
      end

      it "finishes the output line, then lets the error through" do
        expect {
          expect { console_env.reload }.to raise_error(SyntaxError, "unexpected end-of-input")
        }.to output("Reloading... failed. Fix the error, then call `reload` again.\n").to_stdout
      end
    end

    context "when the app has code reloading disabled" do
      let(:app) { build_app(code_reloading: false, reloadable: true) }

      it "falls back to re-execing the console" do
        expect(Kernel).to receive(:exec).with(/console/)

        expect { console_env.reload }.to output(/Reloading\.\.\./).to_stdout
      end
    end

    context "when the app predates in-place reloading" do
      let(:app) { build_app(code_reloading: true, reloadable: false) }

      it "falls back to re-execing the console" do
        expect(Kernel).to receive(:exec).with(/console/)

        expect { console_env.reload }.to output(/Reloading\.\.\./).to_stdout
      end
    end
  end
end
