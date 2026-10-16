# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Command do
  around do |example|
    original_hanami_env = ENV["HANAMI_ENV"]
    example.run
  ensure
    ENV["HANAMI_ENV"] = original_hanami_env
  end

  context "#call" do
    subject { cmd.new }

    let(:cmd) do
      Class.new(described_class) do
        def call(**)
        end
      end
    end

    it "invokes Hanami::Env.load" do
      expect(Hanami::Env).to receive(:load)

      subject.call
    end

    context "when the command's #call declares only some params" do
      let(:cmd) do
        Class.new(described_class) do
          attr_reader :received

          def call(name:)
            @received = {name:}
          end
        end
      end

      it "passes on only the declared params" do
        subject.call(name: "x", env: "test", other: 1)

        expect(subject.received).to eq(name: "x")
      end
    end

    context "when a subclass does not define #call" do
      let(:base) do
        Class.new(described_class) do
          attr_reader :received

          def call(name:)
            @received = {name:}
          end
        end
      end

      let(:cmd) { Class.new(base) }

      it "passes on only the params declared by the inherited #call" do
        subject.call(name: "x", env: "test", other: 1)

        expect(subject.received).to eq(name: "x")
      end
    end

    context "when a subclass's #call calls super" do
      let(:base) do
        Class.new(described_class) do
          attr_reader :received

          def call(name:, **opts)
            @received = {name:, **opts}
          end
        end
      end

      let(:cmd) do
        Class.new(base) do
          def call(name:, **)
            super(name: name.upcase)
          end
        end
      end

      it "loads the env once, and leaves the params given to super alone" do
        expect(Hanami::Env).to receive(:load).once

        subject.call(name: "x", env: "test")

        expect(subject.received).to eq(name: "X")
      end
    end

    context "when a subclass's #call gives super params that it does not declare itself" do
      let(:base) do
        Class.new(described_class) do
          attr_reader :received

          def call(name:, force: false)
            @received = {name:, force:}
          end
        end
      end

      let(:cmd) do
        Class.new(base) do
          def call(name:)
            super(name:, force: true)
          end
        end
      end

      it "passes those params to the superclass's #call" do
        subject.call(name: "x", env: "test")

        expect(subject.received).to eq(name: "x", force: true)
      end
    end

    context "when a subclass's #call does not call super" do
      let(:base) do
        Class.new(described_class) do
          def call(**)
          end
        end
      end

      let(:cmd) do
        Class.new(base) do
          def call(name:)
          end
        end
      end

      it "sets HANAMI_ENV from --env" do
        subject.call(name: "x", env: "test")

        expect(ENV["HANAMI_ENV"]).to eq "test"
      end
    end
  end

  describe ".options" do
    it "declares --env once for a subclass of a subclass" do
      klass = Class.new(Class.new(described_class))

      expect(klass.options.map(&:name).count(:env)).to eq 1
    end
  end
end
