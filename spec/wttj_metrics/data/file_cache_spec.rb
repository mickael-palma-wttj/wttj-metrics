# frozen_string_literal: true

RSpec.describe WttjMetrics::Data::FileCache do
  subject(:cache) { described_class.new(temp_dir) }

  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'creates cache directory if it does not exist' do
      cache_dir = File.join(temp_dir, 'new_cache')
      described_class.new(cache_dir)
      expect(Dir.exist?(cache_dir)).to be true
    end

    it 'uses default cache directory when none provided' do
      cache = described_class.new
      expect(cache.cache_dir).to include('tmp/cache')
    end
  end

  describe '#fetch' do
    let(:cache_key) { 'test_data' }
    let(:test_data) { { 'key' => 'value', 'number' => 42 } }

    context 'when cache is empty' do
      it 'calls the block and caches the result' do
        result = cache.fetch(cache_key) { test_data }

        expect(result).to eq(test_data)
        expect(File.exist?(File.join(temp_dir, "#{cache_key}.json"))).to be true
      end

      it 'writes JSON data to file' do
        cache.fetch(cache_key) { test_data }

        cached_content = File.read(File.join(temp_dir, "#{cache_key}.json"))
        parsed_data = JSON.parse(cached_content)
        expect(parsed_data).to eq(test_data)
      end
    end

    context 'when cache exists and is fresh' do
      before do
        cache.fetch(cache_key) { test_data }
      end

      it 'returns cached data without calling block' do
        block_called = false
        result = cache.fetch(cache_key, max_age_hours: 24) do
          block_called = true
          { 'new' => 'data' }
        end

        expect(result).to eq(test_data)
        expect(block_called).to be false
      end
    end

    context 'when cache exists but is stale' do
      before do
        cache.fetch(cache_key) { test_data }
        # Make the cache file old
        cache_file = File.join(temp_dir, "#{cache_key}.json")
        File.utime(Time.now - (48 * 3600), Time.now - (48 * 3600), cache_file)
      end

      it 'calls block and updates cache' do
        new_data = { 'updated' => 'value' }
        result = cache.fetch(cache_key, max_age_hours: 24) { new_data }

        expect(result).to eq(new_data)

        cached_content = File.read(File.join(temp_dir, "#{cache_key}.json"))
        expect(JSON.parse(cached_content)).to eq(new_data)
      end
    end

    context 'with custom max_age_hours' do
      it 'respects custom max age' do
        cache.fetch(cache_key, max_age_hours: 1) { test_data }

        # Make file 2 hours old
        cache_file = File.join(temp_dir, "#{cache_key}.json")
        File.utime(Time.now - (2 * 3600), Time.now - (2 * 3600), cache_file)

        new_data = { 'fresh' => 'data' }
        result = cache.fetch(cache_key, max_age_hours: 1) { new_data }

        expect(result).to eq(new_data)
      end
    end
  end

  describe '#clear!' do
    before do
      cache.fetch('key1') { { data: 1 } }
      cache.fetch('key2') { { data: 2 } }
    end

    it 'removes all cached files' do
      expect(Dir.entries(temp_dir).size).to be > 2 # . and .. plus files

      cache.clear!

      entries = Dir.entries(temp_dir) - %w[. ..]
      expect(entries).to be_empty
    end

    it 'recreates cache directory' do
      cache.clear!
      expect(Dir.exist?(temp_dir)).to be true
    end
  end

  describe '#cache_dir' do
    it 'returns the cache directory path' do
      expect(cache.cache_dir).to eq(temp_dir)
    end
  end
end
