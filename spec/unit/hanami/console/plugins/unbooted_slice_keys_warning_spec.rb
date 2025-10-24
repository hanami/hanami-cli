# frozen_string_literal: true

RSpec.describe Hanami::Console::Plugins::UnbootedSliceWarnings, :app do
  let(:context) { Hanami::Console::Context.new(app) }
  let(:console_env) { Object.new.extend(context) }

  after do
    Hanami::Console::Plugins::UnbootedSliceWarnings.deactivate
  end

  context "when app is not booted" do
    it "shows a warning the first time a slice's keys method is called" do
      expect { console_env.instance_eval { app.keys } }
        .to output(%(Warning: Test::App is not booted. Run `Test::App.boot` to load all components, or launch the console with `--boot`.\n))
        .to_stderr
    end

    it "only shows the warning once per console session per slice" do
      # Create a second slice for testing
      stub_const("AnotherSlice", Class.new(Hanami::Slice))

      expect { console_env.instance_eval { app.keys } }
        .to output(/Test::App is not booted/).to_stderr
      expect { console_env.instance_eval { app.keys } }
        .not_to output.to_stderr

      expect { console_env.instance_eval { AnotherSlice.keys } }
        .to output(/AnotherSlice is not booted/).to_stderr
      expect { console_env.instance_eval { AnotherSlice.keys } }
        .not_to output.to_stderr
    end

    it "still returns the keys from the slice" do
      result = nil
      original_keys = app.keys
      expect {
        result = console_env.instance_eval { app.keys }
      }.to output(/Test::App is not booted/).to_stderr

      expect(result).to eq(original_keys)
    end
  end

  context "when app is booted" do
    before do
      app.boot
    end

    it "does not show a warning" do
      expect { console_env.instance_eval { app.keys } }
        .not_to output.to_stderr
    end
  end
end
