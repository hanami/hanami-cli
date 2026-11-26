# frozen_string_literal: true

RSpec.describe Hanami::CLI::Files do
  subject(:fs) { described_class.new(memory: true, stdout:) }

  let(:stdout) { StringIO.new }

  describe "#create_or_skip" do
    context "when the file does not exist" do
      it "creates the file" do
        fs.create_or_skip("spec/thing_spec.rb", "new content")

        expect(fs.read("spec/thing_spec.rb")).to eq "new content"
        expect(stdout.string).to eq "  create  spec/thing_spec.rb\n"
      end
    end

    context "when the file exists" do
      before do
        fs.write("spec/thing_spec.rb", "existing content")
        stdout.truncate(0)
        stdout.rewind
      end

      it "leaves the file alone and reports it as skipped" do
        fs.create_or_skip("spec/thing_spec.rb", "new content")

        expect(fs.read("spec/thing_spec.rb")).to eq "existing content"
        expect(stdout.string).to eq "    skip  spec/thing_spec.rb\n"
      end

      it "overwrites the file when force is true" do
        fs.create_or_skip("spec/thing_spec.rb", "new content", force: true)

        expect(fs.read("spec/thing_spec.rb")).to eq "new content"
        expect(stdout.string).to eq "  update  spec/thing_spec.rb\n"
      end
    end
  end
end
