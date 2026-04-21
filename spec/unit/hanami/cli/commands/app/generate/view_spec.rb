# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::View, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  # it "raises error if action name doesn't respect the convention" do
  #   expect {
  #     subject.call(name: "foo")
  #   }.to raise_error(Hanami::CLI::InvalidActionNameError, "cannot parse action name: `foo'\n\texample: `hanami generate action users.show'")
  # end

  context "generating for app" do
    it "generates a view in a top-level namespace" do
      within_application_directory do
        subject.call(name: "users.index")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Views
              module Users
                class Index < Test::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/users/index.rb")).to eq(view_file)
        expect(output).to include("Created app/views/users/index.rb")

        # template
        expect(fs.directory?("app/templates/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Test::Views::Users::Index</h1>
        EXPECTED

        expect(fs.read("app/templates/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created app/templates/users/index.html.erb")
      end
    end

    it "generates a view in a deeper namespace" do
      within_application_directory do
        subject.call(name: "special.users.index")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Views
              module Special
                module Users
                  class Index < Test::View
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/special/users/index.rb")).to eq(view_file)
        expect(output).to include("Created app/views/special/users/index.rb")

        # template
        expect(fs.directory?("app/templates/special/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Test::Views::Special::Users::Index</h1>
        EXPECTED

        expect(fs.read("app/templates/special/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created app/templates/special/users/index.html.erb")
      end
    end

    it "allows to specify slim template engine" do
      within_application_directory do
        subject.call(name: "special.users.index", template_engine: "slim")

        template_file = <<~EXPECTED
          h1 Test::Views::Special::Users::Index
        EXPECTED
        expect(fs.read("app/templates/special/users/index.html.slim")).to eq(template_file)
      end
    end

    it "allows to specify HAML template engine" do
      within_application_directory do
        subject.call(name: "special.users.index", template_engine: "haml")

        template_file = <<~EXPECTED
          %h1 Test::Views::Special::Users::Index
        EXPECTED
        expect(fs.read("app/templates/special/users/index.html.haml")).to eq(template_file)
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

      it "uses the configured template engine" do
        within_application_directory do
          subject.call(name: "users.index")

          template_file = <<~EXPECTED
            h1 Test::Views::Users::Index
          EXPECTED

          expect(fs.read("app/templates/users/index.html.slim")).to eq(template_file)
          expect(output).to include("Created app/templates/users/index.html.slim")
        end
      end

      it "allows overriding the configured template engine" do
        within_application_directory do
          subject.call(name: "users.index", template_engine: "haml")

          template_file = <<~EXPECTED
            %h1 Test::Views::Users::Index
          EXPECTED

          expect(fs.read("app/templates/users/index.html.haml")).to eq(template_file)
          expect(output).to include("Created app/templates/users/index.html.haml")
        end
      end
    end

    context "with existing view file" do
      let(:file_path) { "app/views/users/index.rb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "users.index") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "app/templates/users/index.html.erb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect do
            subject.call(name: "users.index")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end

    context "with existing files and force flag" do
      let(:view_file_path) { "app/views/users/index.rb" }
      let(:template_file_path) { "app/templates/users/index.html.erb" }

      before do
        within_application_directory do
          fs.write(view_file_path, "existing view content")
          fs.write(template_file_path, "existing template content")
        end
      end

      it "overwrites the view file" do
        within_application_directory do
          subject.call(name: "users.index", force: true)
          expect(output).to include("Created #{view_file_path}")
          expect(fs.read(view_file_path)).to include("class Index < Test::View")
        end
      end

      it "overwrites the template file" do
        within_application_directory do
          subject.call(name: "users.index", force: true)
          expect(output).to include("Created #{template_file_path}")
          expect(fs.read(template_file_path)).to eq("<h1>Test::Views::Users::Index</h1>\n")
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a view in a top-level namespace" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "users.index", slice: "main")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module Views
              module Users
                class Index < Main::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/views/users/index.rb")).to eq(view_file)
        expect(output).to include("Created slices/main/views/users/index.rb")

        # template
        expect(fs.directory?("slices/main/templates/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Main::Views::Users::Index</h1>
        EXPECTED

        expect(fs.read("slices/main/templates/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created slices/main/templates/users/index.html.erb")
      end
    end
    it "allows to specify slim template engine" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "users.index", slice: "main", template_engine: "slim")

        template_file = <<~EXPECTED
          h1 Main::Views::Users::Index
        EXPECTED
        expect(fs.read("slices/main/templates/users/index.html.slim")).to eq(template_file)
      end
    end

    it "allows to specify HAML template engine" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "users.index", slice: "main", template_engine: "haml")

        template_file = <<~EXPECTED
          %h1 Main::Views::Users::Index
        EXPECTED
        expect(fs.read("slices/main/templates/users/index.html.haml")).to eq(template_file)
      end
    end

    context "with existing view file" do
      let(:file_path) { "slices/main/views/users/index.rb" }

      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "users.index", slice: "main") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "slices/main/templates/users/index.html.erb" }

      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write(file_path, "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect do
            subject.call(name: "users.index", slice: "main")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
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
