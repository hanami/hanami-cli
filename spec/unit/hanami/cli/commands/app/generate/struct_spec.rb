# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Struct, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:app) { Hanami.app.namespace }

  def output = out.string.chomp

  def error_output = err.string.chomp

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

    context "with existing file" do
      let(:file_path) { "app/structs/book/published/hardcover.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book/published/hardcover")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "when the struct namespace includes the app name" do
      it "namespaces the struct" do
        subject.call(name: "test.book")

        expect(fs.read("app/structs/test/book.rb")).to eq(<<~EXPECTED)
          # frozen_string_literal: true

          module Test
            module Structs
              module Test
                class Book < ::Test::DB::Struct
                end
              end
            end
          end
        EXPECTED
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

    context "with existing file" do
      let(:file_path) { "slices/main/structs/book/draft_book.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book.draft_book", slice: "main")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "when the struct namespace includes the slice name" do
      it "namespaces the struct" do
        fs.mkdir("slices/main")
        subject.call(name: "main.book", slice: "main")

        expect(fs.read("slices/main/structs/main/book.rb")).to eq(<<~EXPECTED)
          # frozen_string_literal: true

          module Main
            module Structs
              module Main
                class Book < ::Main::DB::Struct
                end
              end
            end
          end
        EXPECTED
      end
    end
  end
end
