# frozen_string_literal: true

RSpec.describe Hanami::CLI::Command do
  # Commands are given their streams and `fs` before `#initialize` runs, so they have no `super`
  # to call.
  #
  # rubocop:disable Lint/MissingSuper
  describe ".new" do
    let(:out) { StringIO.new }
    let(:memory_fs) { Hanami::CLI::Files.new(memory: true, stdout: out) }

    it "gives a subclass its streams and fs without them reaching #initialize" do
      command_class = Class.new(described_class) do
        attr_reader :dep

        def initialize(dep: nil)
          @dep = dep
        end
      end

      command = command_class.new(stdout: out, fs: memory_fs, dep: "dep")

      expect(command.dep).to eq "dep"
      expect(command.fs).to be memory_fs
    end

    # This is the reason we do not call `Dry::CLI::Command.new`: taking the streams ourselves is
    # what lets us set `fs` before `#initialize` too.
    it "makes the streams and fs available inside #initialize" do
      command_class = Class.new(described_class) do
        attr_reader :seen

        def initialize
          @seen = [stdout, fs]
        end
      end

      command = command_class.new(stdout: out, fs: memory_fs)

      expect(command.seen[0].raw).to be out
      expect(command.seen[1]).to be memory_fs
    end

    it "builds an fs reporting to the command's own stdout when not given one" do
      # Calling the reporter directly keeps this about the wiring, with no file system to clean up
      described_class.new(stdout: out).fs.send(:created, "some/file.rb")

      expect(out.string).to eq "Created some/file.rb\n"
    end

    it "passes along everything else the subclass asks for" do
      command_class = Class.new(described_class) do
        attr_reader :args, :block

        def initialize(*args, **kwargs, &block)
          @args = [args, kwargs]
          @block = block
        end
      end

      command = command_class.new(1, 2, stdout: out, dep: "dep") { :called }

      expect(command.args).to eq [[1, 2], {dep: "dep"}]
      expect(command.block.call).to be :called
    end

    it "auto-assigns the fs alongside the streams Dry::CLI::Command auto-assigns" do
      expect(described_class.auto_assign_keywords).to eq %i[stderr stdin stdout fs]
    end
  end
  # rubocop:enable Lint/MissingSuper
end
