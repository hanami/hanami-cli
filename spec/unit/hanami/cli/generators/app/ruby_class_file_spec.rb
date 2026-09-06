# frozen_string_literal: true

RSpec.describe Hanami::CLI::Generators::App::RubyClassFile do
  subject(:ruby_class_file) do
    described_class.new(
      fs: fs,
      inflector: inflector,
      key: key,
      namespace: "Bookshelf",
      base_path: "app",
      extra_namespace: extra_namespace
    )
  end

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, stdout: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:extra_namespace) { nil }

  describe "#fully_qualified_name" do
    context "without an extra_namespace" do
      context "key with no nested segments" do
        let(:key) { "add" }

        it "returns the correct constant name" do
          expect(ruby_class_file.fully_qualified_name).to eq("Bookshelf::Add")
        end
      end

      context "key with nested segments" do
        let(:key) { "posts.operations.create" }

        it "returns the correct constant name" do
          expect(ruby_class_file.fully_qualified_name).to eq("Bookshelf::Posts::Operations::Create")
        end
      end
    end

    context "with an extra_namespace" do
      let(:extra_namespace) { "actions" }
      let(:key) { "books.add" }

      it "returns the correct constant name" do
        expect(ruby_class_file.fully_qualified_name).to eq("Bookshelf::Actions::Books::Add")
      end
    end
  end
end
