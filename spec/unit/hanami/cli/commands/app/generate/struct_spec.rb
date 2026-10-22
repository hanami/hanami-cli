# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Struct, :app do
  subject { described_class.new(fs:, stdout:, stderr:) }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout:) }
  let(:app) { Hanami.app.namespace }

  def output = stdout.string.chomp

  context "generating for app" do
    it "generates a struct without a namespace" do
      subject.call(name: "book")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            class Book < Test::DB::Struct
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book.rb")
    end

    it "generates a struct in a namespace with default separator" do
      subject.call(name: "book.book_draft")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            module Book
              class BookDraft < Test::DB::Struct
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book/book_draft.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book/book_draft.rb")
    end

    it "generates an struct in a deep namespace with slash separators" do
      subject.call(name: "book/published/hardcover")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            module Book
              module Published
                class Hardcover < Test::DB::Struct
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book/published/hardcover.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book/published/hardcover.rb")
    end

    context "without base struct" do
      it "generates the app base struct" do
        subject.call(name: "book")

        base_struct = <<~EXPECTED
          # frozen_string_literal: true

          require "hanami/db/struct"

          module Test
            module DB
              class Struct < Hanami::DB::Struct
              end
            end
          end
        EXPECTED

        expect(fs.read("app/db/struct.rb")).to eq(base_struct)
        expect(output).to include("Created app/db/struct.rb")
      end
    end

    context "with base struct" do
      before do
        fs.write("app/db/struct.rb", "existing base struct")
        stdout.truncate 0
      end

      it "does not overwrite the app base struct" do
        subject.call(name: "book")

        expect(fs.read("app/db/struct.rb")).to eq("existing base struct")
        expect(output).not_to include("Created app/db/struct.rb")
        expect(fs.exist?("app/structs/book.rb")).to be(true)
      end
    end

    context "with existing file" do
      let(:file_path) { "app/structs/book/published/hardcover.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book/published/hardcover")
        end.to raise_error Hanami::CLI::FileAlreadyExistsError, Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
      end
    end
  end

  context "generating for a slice" do
    it "generates a struct in a top-level namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book", slice: "main")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Structs
            class Book < Main::DB::Struct
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/structs/book.rb")).to eq(struct_file)
      expect(output).to include("Created slices/main/structs/book.rb")
    end

    it "generates a struct in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.draft_book", slice: "main")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Structs
            module Book
              class DraftBook < Main::DB::Struct
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/structs/book/draft_book.rb")).to eq(struct_file)
      expect(output).to include("Created slices/main/structs/book/draft_book.rb")
    end

    context "without base structs" do
      it "generates the app and slice base structs" do
        fs.mkdir("slices/main")
        subject.call(name: "book", slice: "main")

        slice_base_struct = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module DB
              class Struct < Test::DB::Struct
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/db/struct.rb")).to eq(slice_base_struct)
        expect(output).to include("Created slices/main/db/struct.rb")
        expect(fs.exist?("app/db/struct.rb")).to be(true)
        expect(output).to include("Created app/db/struct.rb")
      end
    end

    context "with base structs" do
      before do
        fs.write("app/db/struct.rb", "existing app base struct")
        fs.write("slices/main/db/struct.rb", "existing slice base struct")
        stdout.truncate 0
      end

      it "does not overwrite the base structs" do
        subject.call(name: "book", slice: "main")

        expect(fs.read("app/db/struct.rb")).to eq("existing app base struct")
        expect(fs.read("slices/main/db/struct.rb")).to eq("existing slice base struct")
        expect(output).not_to include("Created app/db/struct.rb")
        expect(output).not_to include("Created slices/main/db/struct.rb")
        expect(fs.exist?("slices/main/structs/book.rb")).to be(true)
      end
    end

    context "with existing file" do
      let(:file_path) { "slices/main/structs/book/draft_book.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book.draft_book", slice: "main")
        end.to raise_error Hanami::CLI::FileAlreadyExistsError, Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
      end
    end
  end
end
