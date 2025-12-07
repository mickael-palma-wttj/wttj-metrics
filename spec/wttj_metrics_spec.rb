# frozen_string_literal: true

RSpec.describe WttjMetrics do
  describe '.root' do
    it 'returns the application root path' do
      expect(described_class.root).to be_a(Pathname)
      expect(described_class.root.to_s).to end_with('wttj-metrics')
    end
  end

  describe '.loader' do
    it 'returns a Zeitwerk loader instance' do
      expect(described_class.loader).to be_a(Zeitwerk::Loader)
    end

    it 'returns the same instance on multiple calls' do
      loader1 = described_class.loader
      loader2 = described_class.loader
      expect(loader1).to be(loader2)
    end
  end

  describe '.setup!' do
    it 'sets up the Zeitwerk loader' do
      # Already called during require, so just verify it doesn't raise
      expect { described_class.setup! }.not_to raise_error
    end
  end

  describe '.eager_load!' do
    it 'eager loads all files' do
      expect { described_class.eager_load! }.not_to raise_error
    end
  end

  describe WttjMetrics::Config do
    describe '.linear_api_url' do
      it 'returns the Linear API URL' do
        expect(described_class.linear_api_url).to eq('https://api.linear.app/graphql')
      end
    end

    describe '.linear_api_key' do
      context 'when LINEAR_API_KEY is set' do
        before do
          allow(ENV).to receive(:fetch).with('LINEAR_API_KEY', nil).and_return('test_key_123')
        end

        it 'returns the API key from ENV' do
          expect(described_class.linear_api_key).to eq('test_key_123')
        end
      end

      context 'when LINEAR_API_KEY is not set' do
        before do
          allow(ENV).to receive(:fetch).with('LINEAR_API_KEY', nil).and_return(nil)
        end

        it 'returns nil' do
          expect(described_class.linear_api_key).to be_nil
        end
      end
    end

    describe '.csv_output_path' do
      context 'when CSV_OUTPUT_PATH is set' do
        before do
          allow(ENV).to receive(:[]).with('CSV_OUTPUT_PATH').and_return('custom/path.csv')
        end

        it 'returns the custom path' do
          expect(described_class.csv_output_path).to eq('custom/path.csv')
        end
      end

      context 'when CSV_OUTPUT_PATH is not set' do
        before do
          allow(ENV).to receive(:[]).with('CSV_OUTPUT_PATH').and_return(nil)
        end

        it 'returns the default path' do
          expect(described_class.csv_output_path).to eq('tmp/metrics.csv')
        end
      end
    end

    describe '.validate!' do
      context 'when LINEAR_API_KEY is set' do
        before do
          allow(described_class).to receive(:linear_api_key).and_return('test_key')
        end

        it 'does not raise an error' do
          expect { described_class.validate! }.not_to raise_error
        end
      end

      context 'when LINEAR_API_KEY is not set' do
        before do
          allow(described_class).to receive(:linear_api_key).and_return(nil)
        end

        it 'raises a configuration error' do
          expect { described_class.validate! }.to raise_error(
            WttjMetrics::Error,
            /LINEAR_API_KEY is not set/
          )
        end

        it 'includes all configuration errors in message' do
          expect { described_class.validate! }.to raise_error do |error|
            expect(error.message).to include('Configuration errors:')
            expect(error.message).to include('LINEAR_API_KEY is not set')
          end
        end
      end
    end
  end

  describe WttjMetrics::Error do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end

    it 'can be raised with a message' do
      expect { raise described_class, 'Test error' }.to raise_error(
        described_class,
        'Test error'
      )
    end
  end
end
