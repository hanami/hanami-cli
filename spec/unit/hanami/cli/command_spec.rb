# frozen_string_literal: true

RSpec.describe Hanami::CLI::Command do
  describe ".new" do
    let(:stdout) { StringIO.new }
    let(:memory_fs) { Hanami::CLI::Files.new(memory: true, stdout:) }

    it "takes the fs without passing it to #initialize" do
      command_class = Class.new(described_class) do
        attr_reader :dep

        def initialize(dep: nil)
          @dep = dep
        end
      end

      command = command_class.new(fs: memory_fs, dep: "dep")

      expect(command.dep).to eq "dep"
      expect(command.fs).to be memory_fs
    end

    it "makes the fs available inside #initialize" do
      command_class = Class.new(described_class) do
        attr_reader :seen_fs

        def initialize
          @seen_fs = fs
        end
      end

      expect(command_class.new(fs: memory_fs).seen_fs).to be memory_fs
    end

    it "builds an fs reporting to the command's own stdout when not given one" do
      # Calling the reporter directly keeps this about the wiring, with no file system to clean up
      described_class.new(stdout:).fs.send(:created, "some/file.rb")

      expect(stdout.string).to eq "Created some/file.rb\n"
    end
  end
end
