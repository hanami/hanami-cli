# frozen_string_literal: true

RSpec.describe Hanami::Console::Plugins::SliceReaders do
  subject(:console_env) { Object.new.extend(described_class.new(app)) }

  # Stands in for a SliceRegistrar: enumerable for building the readers, and indexable for
  # resolving a slice by name afterwards.
  let(:registry) do
    Class.new do
      attr_accessor :current

      def initialize(slices) = @slices = slices
      def each(&) = @slices.each(&)
      def [](_name) = @current
    end.new([double("slice", slice_name: :shop)])
  end

  let(:app) { double("app", slices: registry) }

  let(:slice_before) { double("slice before reload") }
  let(:slice_after) { double("slice after reload") }

  it "defines a reader named after each slice" do
    registry.current = slice_before

    expect(console_env).to respond_to(:shop)
    expect(console_env.shop).to be(slice_before)
  end

  it "resolves the slice on each call, so a reload does not leave it stale" do
    # Reloading replaces slice class objects. A reader that closed over the slice it saw at
    # console start would keep handing out one whose container had already been discarded.
    registry.current = slice_before
    expect(console_env.shop).to be(slice_before)

    registry.current = slice_after
    expect(console_env.shop).to be(slice_after)
  end
end
