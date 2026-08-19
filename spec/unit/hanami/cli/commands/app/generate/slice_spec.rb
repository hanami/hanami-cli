# frozen_string_literal: true

require "hanami"
require "securerandom"

RSpec.describe Hanami::CLI::Commands::App::Generate::Slice, :app do
  subject { described_class.new(fs: fs, out: out, err: err, generator: generator) }

  before do
    allow(Hanami).to receive(:bundled?)
    allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(true)
    allow(Hanami).to receive(:bundled?).with("dry-operation").and_return(true)
    allow(Hanami).to receive(:bundled?).with("hanami-db").and_return(true)
    allow(Hanami).to receive(:bundled?).with("hanami-mailer").and_return(true)
    allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(true)
  end

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Test" }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "admin" }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  it "generates slice" do
    within_application_directory do
      subject.call(name: slice)

      # Route
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }

            slice :#{slice}, at: "/#{slice}" do
            end
          end
        end
      CODE

      expect(fs.read("config/routes.rb")).to include(routes)
      expect(output).to include("Created config/routes.rb")

      # Slice directory
      expect(fs.directory?("slices/#{slice}")).to be(true)
      expect(output).to include("Created slices/#{slice}/")

      # Action
      action = <<~CODE
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class Action < #{app}::Action
          end
        end
      CODE

      expect(fs.read("slices/#{slice}/action.rb")).to eq(action)
      expect(output).to include("Created slices/#{slice}/action.rb")
      expect(fs.read("slices/#{slice}/actions/.keep")).to eq("")
      expect(output).to include("Created slices/#{slice}/actions/.keep")

      # Relation
      relation = <<~EXPECTED
        # frozen_string_literal: true

        module Admin
          module DB
            class Relation < Test::DB::Relation
            end
          end
        end
      EXPECTED
      expect(fs.read("slices/admin/db/relation.rb")).to eq(relation)
      expect(output).to include("Created slices/admin/db/relation.rb")
      expect(fs.read("slices/admin/relations/.keep")).to eq("")
      expect(output).to include("Created slices/admin/relations/.keep")

      # Repo
      repo = <<~EXPECTED
        # frozen_string_literal: true

        module Admin
          module DB
            class Repo < Test::DB::Repo
            end
          end
        end
      EXPECTED
      expect(fs.read("slices/admin/db/repo.rb")).to eq(repo)
      expect(output).to include("Created slices/admin/db/repo.rb")
      expect(fs.read("slices/admin/repos/.keep")).to eq("")
      expect(output).to include("Created slices/admin/repos/.keep")

      # Struct
      struct = <<~EXPECTED
        # frozen_string_literal: true

        module Admin
          module DB
            class Struct < Test::DB::Struct
            end
          end
        end
      EXPECTED
      expect(fs.read("slices/admin/db/struct.rb")).to eq(struct)
      expect(output).to include("Created slices/admin/db/struct.rb")
      expect(fs.read("slices/admin/structs/.keep")).to eq("")
      expect(output).to include("Created slices/admin/structs/.keep")

      view = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class View < Test::View
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/view.rb")).to eq(view)
      expect(output).to include("Created slices/#{slice}/view.rb")

      mailer = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class Mailer < Test::Mailer
            # Add common mailer behavior here. See https://hanakai.org/learn/hanami/mailers for details.
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/mailer.rb")).to eq(mailer)
      expect(output).to include("Created slices/#{slice}/mailer.rb")
      expect(fs.read("slices/#{slice}/mailers/.keep")).to eq("")
      expect(output).to include("Created slices/#{slice}/mailers/.keep")

      helpers = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          module Views
            module Helpers
              # Add your view helpers here
            end
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/views/helpers.rb")).to eq(helpers)
      expect(output).to include("Created slices/#{slice}/views/helpers.rb")

      context = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          module Views
            class Context < Test::View::Context
              # Define your view context here. See https://hanakai.org/learn/hanami/views/context/ for details.
            end
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/views/context.rb")).to eq(context)
      expect(output).to include("Created slices/#{slice}/views/context.rb")

      operation = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class Operation < Test::Operation
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/operation.rb")).to eq(operation)
      expect(output).to include("Created slices/#{slice}/operation.rb")

      layout = <<~ERB
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{inflector.humanize(app)} - #{inflector.humanize(slice)}</title>
            <%= favicon_tag %>
            <%= stylesheet_tag "app" %>
          </head>
          <body>
            <%= yield %>
            <%= javascript_tag "app" %>
          </body>
        </html>
      ERB
      expect(fs.read("slices/#{slice}/templates/layouts/app.html.erb")).to eq(layout)
      expect(output).to include("Created slices/#{slice}/templates/layouts/app.html.erb")

      # slices/admin/config/i18n/en.yml
      i18n = <<~EXPECTED
        # Add your translations here. See https://hanakai.org/learn/hanami/i18n for details.
        en:
          hello: "Hello"
      EXPECTED
      expect(fs.read("slices/#{slice}/config/i18n/en.yml")).to eq(i18n)
      expect(output).to include("Created slices/#{slice}/config/i18n/en.yml")

      # slices/admin/assets/js/app.js
      app_js = <<~EXPECTED
        import "../css/app.css";
      EXPECTED
      expect(fs.read("slices/#{slice}/assets/js/app.js")).to eq(app_js)
      expect(output).to include("Created slices/#{slice}/assets/js/app.js")

      # slices/admin/assets/css/app.css
      app_css = <<~EXPECTED
        body {
          background-color: #fff;
          color: #000;
          font-family: sans-serif;
        }
      EXPECTED
      expect(fs.read("slices/#{slice}/assets/css/app.css")).to eq(app_css)
      expect(output).to include("Created slices/#{slice}/assets/css/app.css")

      # slices/admin/assets/images/favicon.ico
      expect(fs.exist?("slices/#{slice}/assets/images/favicon.ico")).to be(true)
    end
  end

  it "ensures that slice URL prefix is valid" do
    within_application_directory do
      subject.call(name: slice_name = generate_random_slice_name)
      expected = %(slice :#{slice_name}, at: "/#{slice_name}" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = generate_random_slice_name, url: "/")
      expected = %(slice :#{slice_name}, at: "/" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = generate_random_slice_name, url: "/foo_bar")
      expected = %(slice :#{slice_name}, at: "/foo_bar" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = generate_random_slice_name, url: "/FooBar")
      expected = %(slice :#{slice_name}, at: "/foo_bar" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      expect { subject.call(name: slice, url: " ") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: ` '")
      expect { subject.call(name: slice, url: "a") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `a'")
      expect { subject.call(name: slice, url: "//") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `//'")
      expect {
        subject.call(name: slice, url: "//FooBar")
      }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `//FooBar'")
    end
  end

  it "generates multiple slices over time" do
    within_application_directory do
      subject.call(name: "admin")
      expect(output).to include("Created config/routes.rb")

      subject.call(name: "billing")

      # Route
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }

            slice :admin, at: "/admin" do
            end

            slice :billing, at: "/billing" do
            end
          end
        end
      CODE

      expect(fs.read("config/routes.rb")).to eq(routes)
      expect(output).to include("Updated config/routes.rb")
    end
  end

  context "without hanami-assets" do
    before do
      allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(false)
    end

    it "generates a slice without hanami-assets" do
      within_application_directory do
        subject.call(name: slice)

        # slices/admin/templates/layouts/app.html.erb
        app_layout = fs.read("slices/#{slice}/templates/layouts/app.html.erb")
        expect(app_layout).to_not match(/favicon/)
        expect(app_layout).to_not match(/css/)
        expect(app_layout).to_not match(/js/)

        # slices/admin/assets/js/app.js
        expect(fs.exist?("slices/admin/assets/js/app.js")).to be(false)

        # slices/admin/app/assets/css/app.css
        expect(fs.exist?("slices/admin/assets/css/app.css")).to be(false)
      end
    end
  end

  context "without hanami-view bundled" do
    before do
      allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(false)
    end

    it "generates a slice without view files" do
      within_application_directory do
        subject.call(name: slice)

        expect(fs.exist?("slices/#{slice}/view.rb")).to be(false)
        expect(fs.exist?("slices/#{slice}/views")).to be(false)
        expect(fs.exist?("slices/#{slice}/templates")).to be(false)
      end
    end
  end

  context "without dry-operation bundled" do
    before do
      allow(Hanami).to receive(:bundled?).with("dry-operation").and_return(false)
    end

    it "generates a slice without base operation" do
      within_application_directory do
        subject.call(name: slice)

        expect(fs.exist?("slices/#{slice}/operation.rb")).to be(false)
      end
    end
  end

  context "without hanami-mailer bundled" do
    before do
      allow(Hanami).to receive(:bundled?).with("hanami-mailer").and_return(false)
    end

    it "generates a slice without base mailer" do
      within_application_directory do
        subject.call(name: slice)

        expect(fs.exist?("slices/#{slice}/mailer.rb")).to be(false)
        expect(fs.exist?("slices/#{slice}/mailers")).to be(false)
      end
    end
  end

  context "with --skip-db" do
    it "generates a slice without hanami-db files" do
      within_application_directory do
        subject.call(name: slice, skip_db: true)

        expect(fs.exist?("slices/admin/db")).to be(false)
        expect(fs.exist?("slices/admin/repos")).to be(false)
        expect(fs.exist?("slices/admin/relations")).to be(false)
        expect(fs.exist?("slices/admin/structs")).to be(false)
      end
    end
  end

  context "without hanami-db bundled" do
    before do
      allow(Hanami).to receive(:bundled?).with("hanami-db").and_return(false)
    end

    it "generates a slice without hanami-db files" do
      within_application_directory do
        subject.call(name: slice)

        expect(fs.exist?("slices/admin/db")).to be(false)
        expect(fs.exist?("slices/admin/repos")).to be(false)
        expect(fs.exist?("slices/admin/relations")).to be(false)
        expect(fs.exist?("slices/admin/structs")).to be(false)
      end
    end
  end

  context "with --skip-route" do
    it "generates a slice without corresponding route" do
      within_application_directory do
        subject.call(name: slice, skip_route: true)

        # Route
        blank_routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              root { "Hello from Hanami" }
            end
          end
        CODE

        expect(fs.read("config/routes.rb")).to include(blank_routes)
      end
    end
  end

  context "with existing file" do
    let(:file_path) { "slices/#{slice}/action.rb" }

    before do
      # Ensure config/routes.rb exists for route injection
      fs.mkdir("config")
      fs.write("config/routes.rb", <<~RUBY
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      RUBY
      )
      fs.write(file_path, "existing content")
    end

    it "exits with error message" do
      expect do
        subject.call(name: slice)
      end.to raise_error SystemExit do |exception|
        expect(exception.status).to eq 1
        expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
      end
    end
  end

  private

  def within_application_directory
    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~RUBY
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      RUBY

      fs.write("config/routes.rb", routes)

      yield
    end
  end

  def generate_random_slice_name
    "random_slice_#{SecureRandom.alphanumeric(16).downcase}"
  end
end
