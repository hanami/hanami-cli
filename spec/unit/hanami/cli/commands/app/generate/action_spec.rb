# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::Action, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }
  let(:namespace) { "users" }
  let(:action) { "index" }
  let(:action_name) { "#{namespace}.#{action}" }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  shared_context "with existing files" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(true)
    end

    context "with existing route file" do
      it "generates action without error" do
        within_application_directory do
          generate_action

          expect(output).to include("Updated config/routes.rb")
          expect(output).to include("Created app/actions/#{namespace}/#{action}.rb")
          expect(output).to include("Created app/views/#{namespace}/#{action}.rb")
          expect(output).to include("Created app/templates/#{namespace}/#{action}.html.erb")
        end
      end
    end

    context "when route already exists in route file" do
      it "exits with error message" do
        expect do
          within_application_directory do
            routes_contents = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  root { "Hello from Hanami" }
                  get "/users", to: "users.index"
                end
              end
            CODE
            fs.write("config/routes.rb", routes_contents)
            generate_action
          end
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq 'Route get "/users", to: "users.index" already exists'
        end
      end
    end

    context "with existing action file" do
      let(:file_path) { "app/actions/#{namespace}/#{action}.rb" }

      before do
        within_application_directory do
          fs.write(file_path, "")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { generate_action }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end

      it "overwrites the file if force flag is passed" do
        within_application_directory do
          subject.call(name: action_name, force: true)
          expect(output).to include("Created #{file_path}")
          expect(fs.read(file_path)).to include("class Index < Test::Action")
        end
      end
    end

    context "with existing view file" do
      let(:file_path) { "app/views/#{namespace}/#{action}.rb" }

      before do
        within_application_directory do
          fs.write(file_path, "")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { generate_action }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end

      it "overwrites the file if force flag is passed" do
        within_application_directory do
          subject.call(name: action_name, force: true)
          expect(output).to include("Created #{file_path}")
          expect(fs.read(file_path)).to include("class Index < Test::View")
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "app/templates/#{namespace}/#{action}.html.erb" }

      before do
        within_application_directory do
          fs.write(file_path, "")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory do
            generate_action
          end
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end

      it "overwrites the file if force flag is passed" do
        within_application_directory do
          subject.call(name: action_name, force: true)
          expect(output).to include("Created #{file_path}")
          expect(fs.read(file_path)).to include("<h1>Test::Views::Users::Index</h1>")
        end
      end
    end
  end

  context "generate for app, without hanami view bundled" do
    it "generates action" do
      within_application_directory do
        subject.call(name: action_name, skip_view: true)

        # Route
        routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              root { "Hello from Hanami" }
              get "/users", to: "users.index"
            end
          end
        CODE

        # route
        expect(fs.read("config/routes.rb")).to eq(routes)
        expect(output).to include("Updated config/routes.rb")

        # action
        action_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Actions
              module #{inflector.camelize(namespace)}
                class #{inflector.camelize(action)} < #{inflector.camelize(app)}::Action
                  def handle(request, response)
                    response.body = self.class.name
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/actions/#{namespace}/#{action}.rb")).to eq(action_file)
        expect(output).to include("Created app/actions/#{namespace}/#{action}.rb")

        expect(fs.directory?("app/views/#{namespace}")).to eq(false)
        expect(fs.exist?("app/views/#{namespace}/#{action}.rb")).to eq(false)
        expect(output).to_not include("Created app/views/#{namespace}/#{action}.rb")

        # template
        expect(fs.directory?("app/templates/#{namespace}")).to eq(false)
        expect(fs.exist?("app/templates/#{namespace}/#{action}.html.erb")).to eq(false)
        expect(output).to_not include("Created app/templates/#{namespace}/#{action}.html.erb")
      end
    end

    it "raises error if action name doesn't respect the convention" do
      expect {
        subject.call(name: "foo")
      }.to raise_error(Hanami::CLI::InvalidActionNameError, "cannot parse action name: `foo'\n\texample: `hanami generate action users.show'")
    end

    it "raises error if HTTP method is unknown" do
      expect {
        subject.call(name: action_name, http_method: "foo")
      }.to raise_error(Hanami::CLI::UnknownHTTPMethodError, "unknown HTTP method: `foo'")
    end

    it "raises error if URL is invalid" do
      expect {
        subject.call(name: action_name, url_path: "//")
      }.to raise_error(Hanami::CLI::InvalidURLError, "invalid URL: `//'")
    end

    it "infers RESTful action URL and HTTP method for routes" do
      within_application_directory do
        subject.call(name: "users.index")
        expect(fs.read("config/routes.rb")).to match(%(get "/users", to: "users.index"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.new")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/new", to: "users.new"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.create")
        expect(fs.read("config/routes.rb")).to match(%(post "/users", to: "users.create"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.edit")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/:id/edit", to: "users.edit"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.update")
        expect(fs.read("config/routes.rb")).to match(%(patch "/users/:id", to: "users.update"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.show")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/:id", to: "users.show"))
        expect(output).to include("Updated config/routes.rb")

        subject.call(name: "users.destroy")
        expect(fs.read("config/routes.rb")).to match(%(delete "/users/:id", to: "users.destroy"))
        expect(output).to include("Updated config/routes.rb")
      end
    end

    it "allows to non-RESTful action URL" do
      within_application_directory do
        subject.call(name: "talent.apply", url_path: "/talent/apply")
        expect(fs.read("config/routes.rb")).to match(%(get "/talent/apply", to: "talent.apply"))
        expect(output).to include("Updated config/routes.rb")
      end
    end

    it "allows to specify action URL" do
      within_application_directory do
        subject.call(name: action_name, url_path: "/people")
        expect(fs.read("config/routes.rb")).to match(%(get "/people", to: "users.index"))
        expect(output).to include("Updated config/routes.rb")
      end
    end

    it "allows to specify action HTTP method" do
      within_application_directory do
        subject.call(name: action_name, http_method: "put")
        expect(fs.read("config/routes.rb")).to match(%(put "/users", to: "users.index"))
        expect(output).to include("Updated config/routes.rb")
      end
    end

    it "allows to specify nested action name" do
      within_application_directory do
        action_name = "api/users.thing"
        subject.call(name: action_name, skip_view: true)

        expect(fs.read("config/routes.rb")).to match(%(get "/api/users/thing", to: "api.users.thing"))
        expect(output).to include("Updated config/routes.rb")

        action_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Actions
              module API
                module Users
                  class Thing < #{inflector.camelize(app)}::Action
                    def handle(request, response)
                      response.body = self.class.name
                    end
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/actions/api/users/thing.rb")).to eq(action_file)
        expect(output).to include("Created app/actions/api/users/thing.rb")
      end
    end

    xit "allows to specify MIME Type for template" do
      within_application_directory do
        subject.call(name: action_name, format: format = "json")

        expect(fs.exist?("app/actions/#{namespace}/#{action}.rb")).to be(true)
        expect(fs.exist?("app/views/#{namespace}/#{action}.rb")).to be(true)

        # template
        template_file = <<~EXPECTED
        EXPECTED
        expect(fs.read("app/templates/#{namespace}/#{action}.#{format}.erb")).to eq(template_file)
        expect(output).to include(%(Created app/templates/#{namespace}/#{action}.#{format}.erb.))
      end
    end

    it "can skip view creation" do
      within_application_directory do
        subject.call(name: action_name, skip_view: true)

        expect(fs.exist?("app/actions/#{namespace}/#{action}.rb")).to be(true)

        expect(fs.exist?("app/views/#{namespace}/#{action}.rb")).to be(false)
        expect(output).to_not include("app/views/#{namespace}/#{action}.rb")
        expect(fs.exist?("app/templates/#{namespace}/#{action}.html.erb")).to be(false)
        expect(output).to_not include("app/templates/#{namespace}/#{action}.html.erb")
      end
    end

    it "can skip route creation" do
      within_application_directory do
        subject.call(name: "no.route", skip_route: true)

        expect(fs.read("config/routes.rb")).to_not match(%(get "/no/route", to: "no.route"))
        expect(output).to_not include("Updated config/routes.rb")
      end
    end

    it "can skip test creation" do
      within_application_directory do
        subject.call(name: "no.test", skip_tests: true)

        expect(fs.exist?("spec/actions/no/test_spec.rb")).to be(false)
        expect(output).to_not include("Created spec/actions/no/test_spec.rb")
      end
    end

    it "allows to specify slim template engine" do
      within_application_directory do
        subject.call(name: action_name, template_engine: "slim")

        template_file = <<~EXPECTED
          h1 Test::Views::Users::Index
        EXPECTED
        expect(fs.read("app/templates/#{namespace}/#{action}.html.slim")).to eq(template_file)
      end
    end

    it "allows to specify HAML template engine" do
      within_application_directory do
        subject.call(name: action_name, template_engine: "haml")

        template_file = <<~EXPECTED
          %h1 Test::Views::Users::Index
        EXPECTED
        expect(fs.read("app/templates/#{namespace}/#{action}.html.haml")).to eq(template_file)
      end
    end

    include_context "with existing files" do
      let(:generate_action) { subject.call(name: action_name) }
    end
  end

  context "generate for app, with hanami view bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(true)
    end

    it "generates action" do
      within_application_directory do
        subject.call(name: action_name)

        # Route
        routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              root { "Hello from Hanami" }
              get "/users", to: "users.index"
            end
          end
        CODE

        # route
        expect(fs.read("config/routes.rb")).to eq(routes)
        expect(output).to include("Updated config/routes.rb")

        # action
        action_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Actions
              module #{inflector.camelize(namespace)}
                class #{inflector.camelize(action)} < #{inflector.camelize(app)}::Action
                  def handle(request, response)
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/actions/#{namespace}/#{action}.rb")).to eq(action_file)
        expect(output).to include("Created app/actions/#{namespace}/#{action}.rb")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Views
              module #{inflector.camelize(namespace)}
                class #{inflector.camelize(action)} < #{inflector.camelize(app)}::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/#{namespace}/#{action}.rb")).to eq(view_file)
        expect(output).to include("Created app/views/#{namespace}/#{action}.rb")

        # template
        expect(fs.directory?("app/templates/#{namespace}")).to be(true)

        template_file = <<~EXPECTED
          <h1>#{inflector.camelize(app)}::Views::#{inflector.camelize(namespace)}::#{inflector.camelize(action)}</h1>
        EXPECTED

        expect(fs.read("app/templates/#{namespace}/#{action}.html.erb")).to eq(template_file)
        expect(output).to include("Created app/templates/#{namespace}/#{action}.html.erb")
      end
    end

    context "with default_template_engine configured" do
      before do
        allow(Hanami).to receive(:prepare)
        views_config = double(default_template_engine: "slim")
        allow(Hanami.app.config).to receive(:views).and_return(views_config)
      end

      it "uses the configured template engine" do
        within_application_directory do
          subject.call(name: action_name)

          template_file = <<~EXPECTED
            h1 #{inflector.camelize(app)}::Views::#{inflector.camelize(namespace)}::#{inflector.camelize(action)}
          EXPECTED

          expect(fs.read("app/templates/#{namespace}/#{action}.html.slim")).to eq(template_file)
          expect(output).to include("Created app/templates/#{namespace}/#{action}.html.slim")
        end
      end

      it "allows overriding the configured template engine" do
        within_application_directory do
          subject.call(name: action_name, template_engine: "haml")

          template_file = <<~EXPECTED
            %h1 #{inflector.camelize(app)}::Views::#{inflector.camelize(namespace)}::#{inflector.camelize(action)}
          EXPECTED

          expect(fs.read("app/templates/#{namespace}/#{action}.html.haml")).to eq(template_file)
          expect(output).to include("Created app/templates/#{namespace}/#{action}.html.haml")
        end
      end
    end

    context "with nested action name" do
      it "allows to specify nested action name" do
        within_application_directory do
          action_name = "api/users.thing"
          subject.call(name: action_name)

          expect(fs.read("config/routes.rb")).to match(%(get "/api/users/thing", to: "api.users.thing"))
          expect(output).to include("Updated config/routes.rb")

          action_file = <<~EXPECTED
            # frozen_string_literal: true

            module #{inflector.camelize(app)}
              module Actions
                module API
                  module Users
                    class Thing < #{inflector.camelize(app)}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            end
          EXPECTED

          expect(fs.read("app/actions/api/users/thing.rb")).to eq(action_file)
          expect(output).to include("Created app/actions/api/users/thing.rb")
        end
      end
    end

    it "allows route generation to be skipped" do
      within_application_directory do
        subject.call(name: action_name, skip_route: true)

        # Route
        routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              root { "Hello from Hanami" }
            end
          end
        CODE

        # route
        expect(fs.read("config/routes.rb")).to eq(routes)
        expect(output).to_not include("Updated config/routes.rb")

        # action
        action_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Actions
              module #{inflector.camelize(namespace)}
                class #{inflector.camelize(action)} < #{inflector.camelize(app)}::Action
                  def handle(request, response)
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/actions/#{namespace}/#{action}.rb")).to eq(action_file)
        expect(output).to include("Created app/actions/#{namespace}/#{action}.rb")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module #{inflector.camelize(app)}
            module Views
              module #{inflector.camelize(namespace)}
                class #{inflector.camelize(action)} < #{inflector.camelize(app)}::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/#{namespace}/#{action}.rb")).to eq(view_file)
        expect(output).to include("Created app/views/#{namespace}/#{action}.rb")

        # template
        expect(fs.directory?("app/templates/#{namespace}")).to be(true)

        template_file = <<~EXPECTED
          <h1>#{inflector.camelize(app)}::Views::#{inflector.camelize(namespace)}::#{inflector.camelize(action)}</h1>
        EXPECTED

        expect(fs.read("app/templates/#{namespace}/#{action}.html.erb")).to eq(template_file)
        expect(output).to include("Created app/templates/#{namespace}/#{action}.html.erb")
      end
    end

    it "can skip test creation" do
      within_application_directory do
        subject.call(name: "no.test", skip_tests: true)

        expect(fs.exist?("spec/actions/no/test_spec.rb")).to be(false)
        expect(output).to_not include("Created spec/actions/no/test_spec.rb")
      end
    end

    context "RESTful actions" do
      context "CREATE" do
        let(:action) { "create" }

        it "skips view generation when New view is present" do
          within_application_directory do
            # Prepare
            routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  get "/users/new", to: "users.new"
                end
              end
            CODE

            fs.write("config/routes.rb", routes)

            action = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Actions
                  module Users
                    class New < #{app}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            CODE

            fs.write("app/actions/users/new.rb", action)

            view = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Views
                  module Users
                    class New < #{app}::View
                    end
                  end
                end
              end
            CODE

            fs.write("app/views/users/new.rb", view)

            # Invoke the generator
            subject.call(name: action_name)

            # Verify
            expected_routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  get "/users/new", to: "users.new"
                  post "/users", to: "users.create"
                end
              end
            CODE

            # route
            expect(fs.read("config/routes.rb")).to eq(expected_routes)
            expect(output).to include("Updated config/routes.rb")

            expected_action = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Actions
                  module Users
                    class Create < #{app}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            CODE
            expect(fs.read("app/actions/users/create.rb")).to eq(expected_action)
            expect(output).to include("Created app/actions/users/create.rb")

            expect(fs.exist?("app/views/users/create.rb")).to be(false)
            expect(fs.exist?("app/templates/users/create.html.erb")).to be(false)

            expect(output).to_not include("Created app/views/users/create.rb")
            expect(output).to_not include("Created app/templates/users/create.html.erb")
          end
        end

        context "when New view is NOT present" do
          it "generates view" do
            within_application_directory do
              # Prepare
              routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                  end
                end
              CODE

              fs.write("config/routes.rb", routes)

              # Invoke the generator
              subject.call(name: action_name)

              # Verify
              expected_routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                    post "/users", to: "users.create"
                  end
                end
              CODE

              # route
              expect(fs.read("config/routes.rb")).to eq(expected_routes)
              expect(output).to include("Updated config/routes.rb")

              expected_action = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Actions
                    module Users
                      class Create < #{app}::Action
                        def handle(request, response)
                        end
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/actions/users/create.rb")).to eq(expected_action)
              expect(output).to include("Created app/actions/users/create.rb")

              expected_view = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Views
                    module Users
                      class Create < #{app}::View
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/views/users/create.rb")).to eq(expected_view)
              expect(output).to include("Created app/views/users/create.rb")

              expected_template = <<~EXPECTED
                <h1>#{inflector.camelize(app)}::Views::Users::Create</h1>
              EXPECTED

              expect(fs.read("app/templates/users/create.html.erb")).to eq(expected_template)
              expect(output).to include("Created app/templates/users/create.html.erb")
            end
          end

          it "skips view generation if --skip-view is used" do
            within_application_directory do
              # Prepare
              routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                  end
                end
              CODE

              fs.write("config/routes.rb", routes)

              # Invoke the generator
              subject.call(name: action_name, skip_view: true)

              # Verify
              expected_routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                    post "/users", to: "users.create"
                  end
                end
              CODE

              # route
              expect(fs.read("config/routes.rb")).to eq(expected_routes)
              expect(output).to include("Updated config/routes.rb")

              expected_action = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Actions
                    module Users
                      class Create < #{app}::Action
                        def handle(request, response)
                          response.body = self.class.name
                        end
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/actions/users/create.rb")).to eq(expected_action)
              expect(output).to include("Created app/actions/users/create.rb")

              expect(fs.exist?("app/views/users/create.rb")).to be(false)
              expect(fs.exist?("app/templates/users/create.html.erb")).to be(false)

              expect(output).to_not include("Created app/views/users/create.rb")
              expect(output).to_not include("Created app/templates/users/create.html.erb")
            end
          end
        end
      end

      context "UPDATE" do
        let(:action) { "update" }

        it "skips view generation when Edit view is present" do
          within_application_directory do
            # Prepare
            routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  get "/users/:id/edit", to: "users.edit"
                end
              end
            CODE

            fs.write("config/routes.rb", routes)

            action = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Actions
                  module Users
                    class Edit < #{app}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            CODE

            fs.write("app/actions/users/edit.rb", action)

            view = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Views
                  module Users
                    class Edit < #{app}::View
                    end
                  end
                end
              end
            CODE

            fs.write("app/views/users/edit.rb", view)

            # Invoke the generator
            subject.call(name: action_name)

            # Verify
            expected_routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  get "/users/:id/edit", to: "users.edit"
                  patch "/users/:id", to: "users.update"
                end
              end
            CODE

            # route
            expect(fs.read("config/routes.rb")).to eq(expected_routes)
            expect(output).to include("Updated config/routes.rb")

            expected_action = <<~CODE
              # frozen_string_literal: true

              module #{app}
                module Actions
                  module Users
                    class Update < #{app}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            CODE
            expect(fs.read("app/actions/users/update.rb")).to eq(expected_action)
            expect(output).to include("Created app/actions/users/update.rb")

            expect(fs.exist?("app/views/users/update.rb")).to be(false)
            expect(fs.exist?("app/templates/users/update.html.erb")).to be(false)

            expect(output).to_not include("Created app/views/users/update.rb")
            expect(output).to_not include("Created app/templates/users/update.html.erb")
          end
        end

        context "when Edit view is NOT present" do
          it "generates view" do
            within_application_directory do
              # Prepare
              routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                  end
                end
              CODE

              fs.write("config/routes.rb", routes)

              # Invoke the generator
              subject.call(name: action_name)

              # Verify
              expected_routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                    patch "/users/:id", to: "users.update"
                  end
                end
              CODE

              # route
              expect(fs.read("config/routes.rb")).to eq(expected_routes)
              expect(output).to include("Updated config/routes.rb")

              expected_action = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Actions
                    module Users
                      class Update < #{app}::Action
                        def handle(request, response)
                        end
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/actions/users/update.rb")).to eq(expected_action)
              expect(output).to include("Created app/actions/users/update.rb")

              expected_view = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Views
                    module Users
                      class Update < #{app}::View
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/views/users/update.rb")).to eq(expected_view)
              expect(output).to include("Created app/views/users/update.rb")

              expected_template = <<~EXPECTED
                <h1>#{inflector.camelize(app)}::Views::Users::Update</h1>
              EXPECTED

              expect(fs.read("app/templates/users/update.html.erb")).to eq(expected_template)
              expect(output).to include("Created app/templates/users/update.html.erb")
            end
          end

          it "skips view if --skip-view is used" do
            within_application_directory do
              # Prepare
              routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                  end
                end
              CODE

              fs.write("config/routes.rb", routes)

              # Invoke the generator
              subject.call(name: action_name, skip_view: true)

              # Verify
              expected_routes = <<~CODE
                # frozen_string_literal: true

                require "hanami/routes"

                module #{app}
                  class Routes < Hanami::Routes
                    patch "/users/:id", to: "users.update"
                  end
                end
              CODE

              # route
              expect(fs.read("config/routes.rb")).to eq(expected_routes)
              expect(output).to include("Updated config/routes.rb")

              expected_action = <<~CODE
                # frozen_string_literal: true

                module #{app}
                  module Actions
                    module Users
                      class Update < #{app}::Action
                        def handle(request, response)
                          response.body = self.class.name
                        end
                      end
                    end
                  end
                end
              CODE
              expect(fs.read("app/actions/users/update.rb")).to eq(expected_action)
              expect(output).to include("Created app/actions/users/update.rb")

              expect(fs.exist?("app/views/users/update.rb")).to be(false)
              expect(fs.exist?("app/templates/users/update.html.erb")).to be(false)

              expect(output).to_not include("Created app/views/users/update.rb")
              expect(output).to_not include("Created app/templates/users/update.html.erb")
            end
          end
        end
      end
    end

    include_context "with existing files" do
      let(:generate_action) { subject.call(name: action_name) }
    end
  end

  context "generate for a slice" do
    let(:slice) { "main" }

    before { prepare_slice! }

    context "without hanami view bundled" do
      it "generates action" do
        within_application_directory do
          prepare_slice!

          subject.call(name: action_name, slice: slice)

          # Route
          routes = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  get "/users", to: "users.index"
                end
              end
            end
          CODE

          # route
          expect(fs.read("config/routes.rb")).to eq(routes)
          expect(output).to include("Updated config/routes.rb")
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/")

          # action
          expect(fs.directory?("slices/#{slice}/actions/#{namespace}")).to be(true)
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/")

          action_file = <<~EXPECTED
            # frozen_string_literal: true

            module #{inflector.camelize(slice)}
              module Actions
                module #{inflector.camelize(namespace)}
                  class #{inflector.camelize(action)} < #{inflector.camelize(slice)}::Action
                    def handle(request, response)
                      response.body = self.class.name
                    end
                  end
                end
              end
            end
          EXPECTED
          expect(fs.read("slices/#{slice}/actions/#{namespace}/#{action}.rb")).to eq(action_file)
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/#{action}.rb")

          # view
          expect(fs.directory?("slices/#{slice}/views/#{namespace}")).to be(false)
          expect(output).to_not include("Created slices/#{slice}/views/#{namespace}/")
          expect(output).to_not include("Created slices/#{slice}/views/#{namespace}/#{action}.rb")

          # template
          expect(fs.directory?("slices/#{slice}/templates/#{namespace}")).to be(false)
          expect(output).to_not include("Created slices/#{slice}/templates/#{namespace}/")
        end
      end

      context "deeply nested action" do
        let(:namespace) { %w[books bestsellers nonfiction] }
        let(:namespace_name) { namespace.join(".") }
        let(:action) { "index" }
        let(:action_name) { "#{namespace_name}.#{action}" }

        it "generates action" do
          within_application_directory do
            prepare_slice!

            subject.call(slice: slice, name: action_name)

            # Route
            routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  root { "Hello from Hanami" }

                  slice :#{slice}, at: "/#{slice}" do
                    get "/books/bestsellers/nonfiction", to: "books.bestsellers.nonfiction.index"
                  end
                end
              end
            CODE

            # route
            expect(fs.read("config/routes.rb")).to eq(routes)

            # action
            expect(fs.directory?("slices/#{slice}/actions/books/bestsellers/nonfiction")).to be(true)

            action_file = <<~EXPECTED
              # frozen_string_literal: true

              module #{inflector.camelize(slice)}
                module Actions
                  module Books
                    module Bestsellers
                      module Nonfiction
                        class #{inflector.camelize(action)} < #{inflector.camelize(slice)}::Action
                          def handle(request, response)
                            response.body = self.class.name
                          end
                        end
                      end
                    end
                  end
                end
              end
            EXPECTED
            expect(fs.read("slices/#{slice}/actions/books/bestsellers/nonfiction/#{action}.rb")).to eq(action_file)

            # view
            expect(fs.directory?("slices/#{slice}/views/books/bestsellers/nonfiction")).to be(false)
            expect(output).to_not include("Created slices/#{slice}/views/")

            # template
            expect(fs.directory?("slices/#{slice}/templates/")).to be(false)
            expect(output).to_not include("Created slices/#{slice}/templates/")
          end
        end
      end

      it "appends routes within the proper slice block" do
        within_application_directory do
          prepare_slice!
          fs.mkdir("slices/api")

          routes_contents = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  root to: "home.index"
                end

                slice :api, at: "/api" do
                  root to: "home.index"
                end
              end
            end
          CODE
          fs.write("config/routes.rb", routes_contents)

          expected = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  root to: "home.index"
                  get "/users", to: "users.index"
                end

                slice :api, at: "/api" do
                  root to: "home.index"
                  get "/users/:id", to: "users.show"
                end
              end
            end
          CODE

          subject.call(slice: slice, name: "users.index")
          subject.call(slice: "api", name: "users.show")

          expect(fs.read("config/routes.rb")).to eq(expected)
        end
      end

      it "does not add a duplicate route to the slice block" do
        within_application_directory do
          prepare_slice!
          fs.mkdir("slices/api")

          routes_contents = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  get "/home", to: "home.index"
                end
              end
            end
          CODE
          fs.write("config/routes.rb", routes_contents)

          expect do
            subject.call(slice:, name: "home.index")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq 'Route get "/home", to: "home.index" already exists'
          end
        end
      end

      it "raises error if slice is nonexistent" do
        expect {
          subject.call(slice: "foo", name: action_name)
        }.to raise_error(
          Hanami::CLI::MissingSliceError,
          "slice `foo' is missing, please generate with `hanami generate slice foo'"
        )
      end

      it "can skip test creation" do
        within_application_directory do
          prepare_slice!

          subject.call(slice: slice, name: "no.test", skip_tests: true)

          expect(fs.exist?("spec/slices/#{slice}/actions/no/test_spec.rb")).to be(false)
          expect(output).to_not include("Created spec/slices/#{slice}/actions/no/test_spec.rb")
        end
      end
    end

    context "with hanami view bundled" do
      before do
        allow(Hanami).to receive(:bundled?).and_call_original
        allow(Hanami).to receive(:bundled?).with("hanami-view").and_return(true)
      end

      it "generates action with view" do
        within_application_directory do
          prepare_slice!

          subject.call(name: action_name, slice: slice)

          # Route
          routes = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  get "/users", to: "users.index"
                end
              end
            end
          CODE

          # route
          expect(fs.read("config/routes.rb")).to eq(routes)
          expect(output).to include("Updated config/routes.rb")
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/")

          # action
          expect(fs.directory?("slices/#{slice}/actions/#{namespace}")).to be(true)
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/")

          action_file = <<~EXPECTED
            # frozen_string_literal: true

            module #{inflector.camelize(slice)}
              module Actions
                module #{inflector.camelize(namespace)}
                  class #{inflector.camelize(action)} < #{inflector.camelize(slice)}::Action
                    def handle(request, response)
                    end
                  end
                end
              end
            end
          EXPECTED
          expect(fs.read("slices/#{slice}/actions/#{namespace}/#{action}.rb")).to eq(action_file)
          expect(output).to include("Created slices/#{slice}/actions/#{namespace}/#{action}.rb")

          # view
          expect(fs.directory?("slices/#{slice}/views/#{namespace}")).to be(true)
          expect(output).to include("Created slices/#{slice}/views/#{namespace}/")

          view_file = <<~EXPECTED
            # frozen_string_literal: true

            module #{inflector.camelize(slice)}
              module Views
                module #{inflector.camelize(namespace)}
                  class #{inflector.camelize(action)} < #{inflector.camelize(slice)}::View
                  end
                end
              end
            end
          EXPECTED
          expect(fs.read("slices/#{slice}/views/#{namespace}/#{action}.rb")).to eq(view_file)
          expect(output).to include("Created slices/#{slice}/views/#{namespace}/#{action}.rb")

          # template
          expect(fs.directory?("slices/#{slice}/templates/#{namespace}")).to be(true)
          expect(output).to include("Created slices/#{slice}/templates/#{namespace}/")

          template_file = <<~EXPECTED
            <h1>#{inflector.camelize(slice)}::Views::#{inflector.camelize(namespace)}::#{inflector.camelize(action)}</h1>
          EXPECTED
          expect(fs.read("slices/#{slice}/templates/#{namespace}/#{action}.html.erb")).to eq(template_file)
          expect(output).to include("Created slices/#{slice}/templates/#{namespace}/#{action}.html.erb")
        end
      end

      context "RESTful actions" do
        context "CREATE" do
          let(:action) { "create" }

          it "skips view generation when New view is present" do
            prepare_slice!

            # Route
            routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  root { "Hello from Hanami" }

                  slice :#{slice}, at: "/#{slice}" do
                    get "/users/new", to: "users.new"
                  end
                end
              end
            CODE
            fs.write("config/routes.rb", routes)

            action_file = <<~EXPECTED
              # frozen_string_literal: true

              module #{inflector.camelize(slice)}
                module Actions
                  module Users
                    class New < #{inflector.camelize(slice)}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            EXPECTED
            fs.write("slices/#{slice}/actions/users/new.rb", action_file)

            view_file = <<~EXPECTED
              # frozen_string_literal: true

              module #{inflector.camelize(slice)}
                module Views
                  module Users
                    class New < #{inflector.camelize(slice)}::Action
                    end
                  end
                end
              end
            EXPECTED
            fs.write("slices/#{slice}/views/users/new.rb", view_file)

            subject.call(name: action_name, slice: slice)

            expected_routes = <<~CODE
              # frozen_string_literal: true

              require "hanami/routes"

              module #{app}
                class Routes < Hanami::Routes
                  root { "Hello from Hanami" }

                  slice :#{slice}, at: "/#{slice}" do
                    get "/users/new", to: "users.new"
                    post "/users", to: "users.create"
                  end
                end
              end
            CODE

            # route
            expect(fs.read("config/routes.rb")).to eq(expected_routes)
            expect(output).to include("Updated config/routes.rb")
            expect(output).to include("Created slices/#{slice}/actions/#{namespace}/")

            # action
            expected_action = <<~EXPECTED
              # frozen_string_literal: true

              module #{inflector.camelize(slice)}
                module Actions
                  module Users
                    class Create < #{inflector.camelize(slice)}::Action
                      def handle(request, response)
                      end
                    end
                  end
                end
              end
            EXPECTED
            expect(fs.read("slices/#{slice}/actions/#{namespace}/#{action}.rb")).to eq(expected_action)
            expect(output).to include("Created slices/#{slice}/actions/#{namespace}/#{action}.rb")

            # view
            expect(output).to_not include("Created slices/#{slice}/views/#{namespace}/#{action}.rb")
            # template
            expect(output).to_not include("Created slices/#{slice}/templates/#{namespace}/#{action}.html.erb")
          end
        end
      end

      it "can skip test creation" do
        within_application_directory do
          prepare_slice!

          subject.call(slice: slice, name: "no.test", skip_tests: true)

          expect(fs.exist?("spec/slices/#{slice}/actions/no/test_spec.rb")).to be(false)
          expect(output).to_not include("Created spec/slices/#{slice}/actions/no/test_spec.rb")
        end
      end
    end

    context "with routes file under slice directory" do
      it "appends routes to slice route file" do
        within_application_directory do
          app_routes = <<~RUBY
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                root { "Hello from Hanami" }

                slice :api, at: "/api"
              end
            end
          RUBY

          fs.write("config/routes.rb", app_routes)

          fs.mkdir("slices/api")
          fs.write("slices/api/config/routes.rb", <<~RUBY)
            # frozen_string_literal: true

            require "hanami/routes"

            module Api
              class Routes < Hanami::Routes
              end
            end
          RUBY

          subject.call(slice: "api", name: "users.index")
          subject.call(slice: "api", name: "users.show")

          expect(fs.read("config/routes.rb")).to eq(app_routes)
          expect(fs.read("slices/api/config/routes.rb")).to eq(<<~RUBY)
            # frozen_string_literal: true

            require "hanami/routes"

            module Api
              class Routes < Hanami::Routes
                get "/users", to: "users.index"
                get "/users/:id", to: "users.show"
              end
            end
          RUBY
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

  def prepare_slice!
    fs.mkdir("slices/#{slice}")
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

    fs.write("config/routes.rb", routes)
  end
end
