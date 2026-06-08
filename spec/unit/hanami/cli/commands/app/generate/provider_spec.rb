# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::Provider, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  context "generating for app" do
    it "generates the provider" do
      subject.call(name: "mailers")

      provider = <<~EXPECTED
        # frozen_string_literal: true

        Hanami.app.register_provider :mailers do
          # Define your provider here.
          #
          # See https://hanakai.org/learn/hanami/app/providers for details.

          start do
            # Set up and register the provider's components.
          end
        end
      EXPECTED

      expect(fs.read("config/providers/mailers.rb")).to eq(provider)
      expect(output).to include("Created config/providers/mailers.rb")
    end

    it "underscores the provider name" do
      subject.call(name: "ErrorAlerting")

      expect(fs.read("config/providers/error_alerting.rb"))
        .to include("Hanami.app.register_provider :error_alerting do")
      expect(output).to include("Created config/providers/error_alerting.rb")
    end

    context "with existing file" do
      let(:file_path) { "config/providers/mailers.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "mailers")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end

      it "overwrites the file when --force is given" do
        subject.call(name: "mailers", force: true)

        expect(fs.read(file_path)).to include("Hanami.app.register_provider :mailers do")
        expect(output).to include("Created config/providers/mailers.rb")
      end
    end
  end

  context "generating for a slice" do
    it "generates the provider" do
      fs.mkdir("slices/admin")
      subject.call(name: "mailers", slice: "admin")

      provider = <<~EXPECTED
        # frozen_string_literal: true

        Admin::Slice.register_provider :mailers do
          # Define your provider here.
          #
          # See https://hanakai.org/learn/hanami/app/providers for details.

          start do
            # Set up and register the provider's components.
          end
        end
      EXPECTED

      expect(fs.read("slices/admin/config/providers/mailers.rb")).to eq(provider)
      expect(output).to include("Created slices/admin/config/providers/mailers.rb")
    end

    context "with missing slice" do
      it "raises error" do
        expect { subject.call(name: "mailers", slice: "foo") }
          .to raise_error(Hanami::CLI::MissingSliceError)
      end
    end
  end
end
