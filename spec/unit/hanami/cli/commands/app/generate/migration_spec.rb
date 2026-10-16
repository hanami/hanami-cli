# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::Migration, :app do
  subject { described_class.new(fs:, stdout:) }

  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout:) }
  let(:stdout) { StringIO.new }

  def output
    stdout.string.chomp
  end

  let(:app) { Hanami.app.namespace }

  before do
    allow(Time).to receive(:now) { Time.new(2024, 7, 13, 14, 6, 0) }
  end

  context "generating for app" do
    context "Ruby migration" do
      let(:migration_file_contents) { <<~RUBY }
        # frozen_string_literal: true

        ROM::SQL.migration do
          # Add your migration here.
          #
          # See https://hanakai.org/learn/hanami/database/migrations/ for details.
          change do
          end
        end
      RUBY

      it "generates a migration" do
        subject.call(name: "create_posts")

        expect(fs.read("config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/migrate/20240713140600_create_posts.rb
          ✓ Generated migration create_posts
        OUTPUT
      end

      it "generates a migration for a gateway" do
        subject.call(name: "create_posts", gateway: "extra")

        expect(fs.read("config/db/extra_migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/extra_migrate/20240713140600_create_posts.rb
          ✓ Generated migration create_posts
        OUTPUT
      end

      it "generates a migration with underscored version of camel cased name" do
        subject.call(name: "CreatePosts")

        expect(fs.read("config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/migrate/20240713140600_create_posts.rb
          ✓ Generated migration CreatePosts
        OUTPUT
      end

      it "accepts --env, even though its #call does not declare it" do
        # --env sets HANAMI_ENV, which would otherwise leak into later specs
        original_hanami_env = ENV["HANAMI_ENV"]
        subject.call(name: "create_posts", env: "test")

        expect(output).to end_with("✓ Generated migration create_posts")
      ensure
        ENV["HANAMI_ENV"] = original_hanami_env
      end

      it "raises an error if given an invalid name" do
        expect {
          subject.call(name: "create posts")
        }.to raise_error(include_in_order(
          "Invalid migration name: create posts",
          "Name must contain only letters, numbers, and underscores."
        ))
      end
    end

    context "SQL migration" do
      let(:migration_file_contents) { <<~SQL }
        -- Add your migration here.
        --
        -- See https://hanakai.org/learn/hanami/database/migrations/ for details.
        -- @migrate up
        -- @begin
        SELECT 'up SQL query';
        -- @end

        -- @migrate down
        -- @begin
        SELECT 'down SQL query';
        -- @end
      SQL

      it "generates a migration" do
        subject.call(name: "create_posts", sql: true)

        expect(fs.read("config/db/migrate/20240713140600_create_posts.sql")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/migrate/20240713140600_create_posts.sql
          ✓ Generated migration create_posts
        OUTPUT
      end

      it "generates a migration for a gateway" do
        subject.call(name: "create_posts", gateway: "extra", sql: true)

        expect(fs.read("config/db/extra_migrate/20240713140600_create_posts.sql")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/extra_migrate/20240713140600_create_posts.sql
          ✓ Generated migration create_posts
        OUTPUT
      end

      it "generates a migration with underscored version of camel cased name" do
        subject.call(name: "CreatePosts", sql: true)

        expect(fs.read("config/db/migrate/20240713140600_create_posts.sql")).to eq migration_file_contents
        expect(output).to eq(<<~OUTPUT.chomp)
          \  create  config/db/migrate/20240713140600_create_posts.sql
          ✓ Generated migration CreatePosts
        OUTPUT
      end

      it "raises an error if given an invalid name" do
        expect {
          subject.call(name: "create posts", sql: true)
        }.to raise_error(include_in_order(
          "Invalid migration name: create posts",
          "Name must contain only letters, numbers, and underscores."
        ))
      end
    end
  end

  context "generating for a slice" do
    let(:migration_file_contents) { <<~RUBY }
      # frozen_string_literal: true

      ROM::SQL.migration do
        # Add your migration here.
        #
        # See https://hanakai.org/learn/hanami/database/migrations/ for details.
        change do
        end
      end
    RUBY

    it "generates a migration" do
      fs.mkdir("slices/main")
      stdout.truncate 0
      stdout.rewind

      subject.call(name: "create_posts", slice: "main")

      expect(fs.read("slices/main/config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
      expect(output).to eq(<<~OUTPUT.chomp)
        \  create  slices/main/config/db/migrate/20240713140600_create_posts.rb
        ✓ Generated migration create_posts
      OUTPUT
    end
  end
end
