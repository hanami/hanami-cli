# frozen_string_literal: true

RSpec.describe Hanami::CLI::Formatter do
  describe "COLORS" do
    it "defines ANSI color codes" do
      expect(described_class::COLORS).to eq({
                                              reset: "\e[0m",
                                              bold: "\e[1m",
                                              green: "\e[32m",
                                              blue: "\e[34m",
                                              cyan: "\e[36m",
                                              yellow: "\e[33m",
                                              red: "\e[31m",
                                              gray: "\e[90m"
                                            })
    end

    it "is frozen" do
      expect(described_class::COLORS).to be_frozen
    end
  end

  describe "ICONS" do
    it "defines icons for different operations" do
      expect(described_class::ICONS).to eq({
                                             create: "✓",
                                             update: "↻",
                                             info: "→",
                                             warning: "⚠",
                                             error: "✗",
                                             success: "✓"
                                           })
    end

    it "is frozen" do
      expect(described_class::ICONS).to be_frozen
    end
  end

  describe ".colorize" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "wraps text with color codes" do
        result = described_class.colorize("hello", :green)
        expect(result).to eq("\e[32mhello\e[0m")
      end

      it "handles different colors" do
        expect(described_class.colorize("text", :red)).to eq("\e[31mtext\e[0m")
        expect(described_class.colorize("text", :blue)).to eq("\e[34mtext\e[0m")
        expect(described_class.colorize("text", :yellow)).to eq("\e[33mtext\e[0m")
        expect(described_class.colorize("text", :cyan)).to eq("\e[36mtext\e[0m")
        expect(described_class.colorize("text", :gray)).to eq("\e[90mtext\e[0m")
        expect(described_class.colorize("text", :bold)).to eq("\e[1mtext\e[0m")
      end

      it "handles empty text" do
        result = described_class.colorize("", :green)
        expect(result).to eq("\e[32m\e[0m")
      end

      it "handles nil color gracefully" do
        result = described_class.colorize("text", nil)
        expect(result).to eq("text\e[0m")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "returns text without color codes" do
        result = described_class.colorize("hello", :green)
        expect(result).to eq("hello")
      end

      it "handles empty text" do
        result = described_class.colorize("", :green)
        expect(result).to eq("")
      end
    end
  end

  describe ".created" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a create message with green color and icon" do
        result = described_class.created("app/models/user.rb")
        expect(result).to eq("  \e[32m✓\e[0m \e[32mcreate\e[0m  app/models/user.rb")
      end

      it "handles paths with spaces" do
        result = described_class.created("my app/user.rb")
        expect(result).to eq("  \e[32m✓\e[0m \e[32mcreate\e[0m  my app/user.rb")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats a create message without colors" do
        result = described_class.created("app/models/user.rb")
        expect(result).to eq("  ✓ create  app/models/user.rb")
      end
    end
  end

  describe ".created_directory" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a create directory message with green color and icon" do
        result = described_class.created_directory("app/models")
        expect(result).to eq("\e[32m✓\e[0m \e[32mcreate directory\e[0m  app/models")
      end

      it "handles directory paths with spaces" do
        result = described_class.created_directory("my app/models")
        expect(result).to eq("\e[32m✓\e[0m \e[32mcreate directory\e[0m  my app/models")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats a create directory message without colors" do
        result = described_class.created_directory("app/models")
        expect(result).to eq("✓ create directory  app/models")
      end
    end
  end

  describe ".updated" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats an update message with cyan color and icon" do
        result = described_class.updated("config/routes.rb")
        expect(result).to eq("  \e[36m↻\e[0m \e[36mupdate\e[0m  config/routes.rb")
      end

      it "handles paths with spaces" do
        result = described_class.updated("my config/routes.rb")
        expect(result).to eq("  \e[36m↻\e[0m \e[36mupdate\e[0m  my config/routes.rb")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats an update message without colors" do
        result = described_class.updated("config/routes.rb")
        expect(result).to eq("  ↻ update  config/routes.rb")
      end
    end
  end

  describe ".info" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats an info message with blue color and icon" do
        result = described_class.info("Starting server...")
        expect(result).to eq("\e[34m→\e[0m Starting server...")
      end

      it "handles empty text" do
        result = described_class.info("")
        expect(result).to eq("\e[34m→\e[0m ")
      end

      it "handles multiline text" do
        result = described_class.info("Line 1\nLine 2")
        expect(result).to eq("\e[34m→\e[0m Line 1\nLine 2")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats an info message without colors" do
        result = described_class.info("Starting server...")
        expect(result).to eq("→ Starting server...")
      end
    end
  end

  describe ".success" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a success message with green color and icon" do
        result = described_class.success("Application created successfully!")
        expect(result).to eq("\e[32m✓\e[0m \e[32mApplication created successfully!\e[0m")
      end

      it "handles empty text" do
        result = described_class.success("")
        expect(result).to eq("\e[32m✓\e[0m \e[32m\e[0m")
      end

      it "handles multiline text" do
        result = described_class.success("Success!\nAll done.")
        expect(result).to eq("\e[32m✓\e[0m \e[32mSuccess!\nAll done.\e[0m")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats a success message without colors" do
        result = described_class.success("Application created successfully!")
        expect(result).to eq("✓ Application created successfully!")
      end
    end
  end

  describe ".warning" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a warning message with yellow color and icon" do
        result = described_class.warning("This is deprecated")
        expect(result).to eq("\e[33m⚠\e[0m \e[33mwarning\e[0m This is deprecated")
      end

      it "handles empty text" do
        result = described_class.warning("")
        expect(result).to eq("\e[33m⚠\e[0m \e[33mwarning\e[0m ")
      end

      it "handles multiline text" do
        result = described_class.warning("Warning!\nBe careful.")
        expect(result).to eq("\e[33m⚠\e[0m \e[33mwarning\e[0m Warning!\nBe careful.")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats a warning message without colors" do
        result = described_class.warning("This is deprecated")
        expect(result).to eq("⚠ warning This is deprecated")
      end
    end
  end

  describe ".error" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats an error message with red color and icon" do
        result = described_class.error("Something went wrong")
        expect(result).to eq("\e[31m✗\e[0m \e[31merror\e[0m Something went wrong")
      end

      it "handles empty text" do
        result = described_class.error("")
        expect(result).to eq("\e[31m✗\e[0m \e[31merror\e[0m ")
      end

      it "handles multiline text" do
        result = described_class.error("Error!\nCheck the logs.")
        expect(result).to eq("\e[31m✗\e[0m \e[31merror\e[0m Error!\nCheck the logs.")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats an error message without colors" do
        result = described_class.error("Something went wrong")
        expect(result).to eq("✗ error Something went wrong")
      end
    end
  end

  describe ".header" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a header with bold text and newline prefix" do
        result = described_class.header("Configuration")
        expect(result).to eq("\n\e[1mConfiguration\e[0m")
      end

      it "handles empty text" do
        result = described_class.header("")
        expect(result).to eq("\n\e[1m\e[0m")
      end

      it "handles multiline text" do
        result = described_class.header("Header\nSubheader")
        expect(result).to eq("\n\e[1mHeader\nSubheader\e[0m")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats a header without colors but with newline prefix" do
        result = described_class.header("Configuration")
        expect(result).to eq("\nConfiguration")
      end
    end
  end

  describe ".dim" do
    it "returns the text unchanged" do
      result = described_class.dim("secondary text")
      expect(result).to eq("secondary text")
    end

    it "handles empty text" do
      result = described_class.dim("")
      expect(result).to eq("")
    end

    it "handles multiline text" do
      result = described_class.dim("Line 1\nLine 2")
      expect(result).to eq("Line 1\nLine 2")
    end

    it "handles nil input" do
      result = described_class.dim(nil)
      expect(result).to be_nil
    end
  end

  describe "module behavior" do
    it "is a module" do
      expect(described_class).to be_a(Module)
    end

    it "has module_function methods" do
      expect(described_class).to respond_to(:colorize)
      expect(described_class).to respond_to(:created)
      expect(described_class).to respond_to(:updated)
      expect(described_class).to respond_to(:info)
      expect(described_class).to respond_to(:success)
      expect(described_class).to respond_to(:warning)
      expect(described_class).to respond_to(:error)
      expect(described_class).to respond_to(:header)
      expect(described_class).to respond_to(:dim)
    end
  end

  describe "integration scenarios" do
    context "when stdout is a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(true)
      end

      it "formats a complete workflow with different message types" do
        messages = [
          described_class.header("Creating new application"),
          described_class.created_directory("my_app"),
          described_class.created("my_app/config.ru"),
          described_class.updated("my_app/Gemfile"),
          described_class.info("Installing dependencies..."),
          described_class.success("Application created successfully!"),
          described_class.warning("Remember to run bundle install"),
          described_class.dim("Additional notes here")
        ]

        expect(messages).to all(be_a(String))
        expect(messages.join("\n")).to include("Creating new application")
        expect(messages.join("\n")).to include("my_app")
        expect(messages.join("\n")).to include("✓")
        expect(messages.join("\n")).to include("↻")
        expect(messages.join("\n")).to include("→")
        expect(messages.join("\n")).to include("⚠")
      end
    end

    context "when stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "formats messages without ANSI codes" do
        result = described_class.created("test.rb")
        expect(result).not_to include("\e[")
        expect(result).to include("✓")
        expect(result).to include("create")
        expect(result).to include("test.rb")
      end
    end
  end
end
