# frozen_string_literal: true

RSpec.describe WttjMetrics::Services::CacheFactory do
  describe '.enabled' do
    it 'returns a FileCache instance' do
      result = described_class.enabled

      expect(result).to be_a(WttjMetrics::Data::FileCache)
    end

    it 'returns a new instance each time' do
      cache1 = described_class.enabled
      cache2 = described_class.enabled

      expect(cache1).not_to be(cache2)
    end
  end

  describe '.disabled' do
    it 'returns nil' do
      result = described_class.disabled

      expect(result).to be_nil
    end
  end

  describe '.default' do
    it 'returns an enabled cache by default' do
      result = described_class.default

      expect(result).to be_a(WttjMetrics::Data::FileCache)
    end

    it 'behaves the same as .enabled' do
      default_cache = described_class.default
      enabled_cache = described_class.enabled

      expect(default_cache.class).to eq(enabled_cache.class)
    end
  end

  describe 'integration with cache options' do
    context 'when cache is enabled' do
      it 'provides a functional cache instance' do
        cache = described_class.enabled

        expect(cache).to respond_to(:fetch)
        expect(cache).to respond_to(:clear!)
        expect(cache).to respond_to(:cache_dir)
      end
    end

    context 'when cache is disabled' do
      it 'returns nil to indicate no caching' do
        cache = described_class.disabled

        expect(cache).to be_nil
      end
    end
  end
end
