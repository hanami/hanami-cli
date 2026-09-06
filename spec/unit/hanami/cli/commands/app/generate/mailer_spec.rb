# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::Mailer, :app do
  subject { described_class.new(fs: fs, stdout: out, stderr: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  context "generating for app" do
    it "generates a mailer in a top-level namespace" do
      within_application_directory do
        subject.call(name: "welcome")

        mailer_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Mailers
              class Welcome < Test::Mailer
              end
            end
          end
        EXPECTED

        expect(fs.read("app/mailers/welcome.rb")).to eq(mailer_file)
        expect(output).to include("Created app/mailers/welcome.rb")

        expect(fs.read("app/templates/mailers/welcome.html.erb")).to eq("<h1>Test::Mailers::Welcome</h1>\n")
        expect(output).to include("Created app/templates/mailers/welcome.html.erb")

        expect(fs.read("app/templates/mailers/welcome.text.erb")).to eq("Test::Mailers::Welcome\n")
        expect(output).to include("Created app/templates/mailers/welcome.text.erb")
      end
    end

    it "accepts a skip_tests option" do
      within_application_directory do
        subject.call(name: "welcome", skip_tests: true)

        expect(fs.exist?("app/mailers/welcome.rb")).to be(true)
      end
    end

    it "generates a mailer in a deeper namespace" do
      within_application_directory do
        subject.call(name: "notifications.welcome")

        mailer_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Mailers
              module Notifications
                class Welcome < Test::Mailer
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/mailers/notifications/welcome.rb")).to eq(mailer_file)
        expect(output).to include("Created app/mailers/notifications/welcome.rb")

        expect(fs.directory?("app/templates/mailers/notifications")).to be(true)
        expect(fs.read("app/templates/mailers/notifications/welcome.html.erb"))
          .to eq("<h1>Test::Mailers::Notifications::Welcome</h1>\n")
        expect(fs.read("app/templates/mailers/notifications/welcome.text.erb"))
          .to eq("Test::Mailers::Notifications::Welcome\n")
      end
    end

    it "allows specifying Slim template engine for the HTML template" do
      within_application_directory do
        subject.call(name: "welcome", template_engine: "slim")

        expect(fs.read("app/templates/mailers/welcome.html.slim")).to eq("h1 Test::Mailers::Welcome\n")

        # Text templates remain plain ERB
        expect(fs.read("app/templates/mailers/welcome.text.erb")).to eq("Test::Mailers::Welcome\n")
      end
    end

    it "allows specifying HAML template engine for the HTML template" do
      within_application_directory do
        subject.call(name: "welcome", template_engine: "haml")

        expect(fs.read("app/templates/mailers/welcome.html.haml")).to eq("%h1 Test::Mailers::Welcome\n")
        expect(fs.read("app/templates/mailers/welcome.text.erb")).to eq("Test::Mailers::Welcome\n")
      end
    end

    context "with default_template_engine configured" do
      before do
        allow(Hanami).to receive(:bundled?).and_call_original
        allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(true)
        allow(Hanami).to receive(:prepare)

        views_config = double(default_template_engine: "slim")
        allow(Hanami.app.config).to receive(:views).and_return(views_config)
      end

      it "uses the configured template engine for the HTML template" do
        within_application_directory do
          subject.call(name: "welcome")

          expect(fs.read("app/templates/mailers/welcome.html.slim")).to eq("h1 Test::Mailers::Welcome\n")
          expect(output).to include("Created app/templates/mailers/welcome.html.slim")
        end
      end

      it "allows overriding the configured template engine" do
        within_application_directory do
          subject.call(name: "welcome", template_engine: "haml")

          expect(fs.read("app/templates/mailers/welcome.html.haml")).to eq("%h1 Test::Mailers::Welcome\n")
          expect(output).to include("Created app/templates/mailers/welcome.html.haml")
        end
      end
    end

    context "with existing mailer file" do
      let(:file_path) { "app/mailers/welcome.rb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "welcome") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "app/templates/mailers/welcome.html.erb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect do
            subject.call(name: "welcome")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end

    context "with existing files and force flag" do
      let(:mailer_file_path) { "app/mailers/welcome.rb" }
      let(:template_file_path) { "app/templates/mailers/welcome.html.erb" }

      before do
        within_application_directory do
          fs.write(mailer_file_path, "existing mailer content")
          fs.write(template_file_path, "existing template content")
        end
      end

      it "overwrites the mailer file" do
        within_application_directory do
          subject.call(name: "welcome", force: true)
          expect(output).to include("Created #{mailer_file_path}")
          expect(fs.read(mailer_file_path)).to include("class Welcome < Test::Mailer")
        end
      end

      it "overwrites the template file" do
        within_application_directory do
          subject.call(name: "welcome", force: true)
          expect(output).to include("Created #{template_file_path}")
          expect(fs.read(template_file_path)).to eq("<h1>Test::Mailers::Welcome</h1>\n")
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a mailer in a top-level namespace" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "welcome", slice: "main")

        mailer_file = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module Mailers
              class Welcome < Main::Mailer
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/mailers/welcome.rb")).to eq(mailer_file)
        expect(output).to include("Created slices/main/mailers/welcome.rb")

        expect(fs.read("slices/main/templates/mailers/welcome.html.erb")).to eq("<h1>Main::Mailers::Welcome</h1>\n")
        expect(fs.read("slices/main/templates/mailers/welcome.text.erb")).to eq("Main::Mailers::Welcome\n")
      end
    end

    context "with existing mailer file" do
      let(:file_path) { "slices/main/mailers/welcome.rb" }

      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "welcome", slice: "main") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end
  end

  private

  def within_application_directory
    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      CODE

      fs.write("config/routes.rb", routes)

      yield
    end
  end
end
