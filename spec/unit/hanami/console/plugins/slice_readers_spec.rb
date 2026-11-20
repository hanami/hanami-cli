# frozen_string_literal: true

RSpec.describe Hanami::Console::Plugins::SliceReaders do
  subject(:slice_readers) { described_class.new(app) }

  let(:console_env) { Object.new.extend(slice_readers) }

  # Stands in for a SliceRegistrar: it lists slice names and looks slices up by name. Reloading
  # the app replaces the registrar, which `reload` mimics by swapping the slices out.
  let(:registry) do
    Class.new do
      def initialize(slices) = @slices = slices
      def reload(slices) = @slices = slices
      def keys = @slices.keys

      def [](name)
        @slices.fetch(name) { raise Hanami::SliceLoadError, "Slice '#{name}' not found" }
      end
    end.new({shop: shop_before})
  end

  let(:app) { double("app", slices: registry) }

  let(:shop_before) { double("shop slice before reload") }
  let(:shop_after) { double("shop slice after reload") }
  let(:admin) { double("admin slice") }

  it "defines a reader named after each slice" do
    expect(console_env).to respond_to(:shop)
    expect(console_env.shop).to be(shop_before)
  end

  it "resolves the slice on each call, so a reload does not leave it stale" do
    # Reloading replaces slice class objects. A reader that closed over the slice it saw at
    # console start would keep handing out one whose container had already been discarded.
    expect(console_env.shop).to be(shop_before)

    registry.reload(shop: shop_after)

    expect(console_env.shop).to be(shop_after)
  end

  describe "#refresh" do
    it "defines readers for slices added since the last refresh" do
      console_env
      registry.reload(shop: shop_after, admin:)

      slice_readers.refresh

      expect(console_env.admin).to be(admin)
      expect(console_env.shop).to be(shop_after)
    end

    it "removes readers for slices that are gone" do
      console_env
      registry.reload(admin:)

      slice_readers.refresh

      expect(console_env).not_to respond_to(:shop)
      expect { console_env.shop }.to raise_error(NoMethodError)
    end

    it "can refresh more than once" do
      console_env

      registry.reload(admin:)
      slice_readers.refresh
      registry.reload(shop: shop_after)
      slice_readers.refresh

      expect(console_env.shop).to be(shop_after)
      expect(console_env).not_to respond_to(:admin)
    end
  end
end
