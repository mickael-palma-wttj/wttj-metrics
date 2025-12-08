# frozen_string_literal: true

require 'logger'

RSpec.describe WttjMetrics::Services::MetricsCollector do
  let(:logger) { instance_double(Logger, info: nil) }
  let(:options) do
    double(
      'Options',
      cache_enabled: true,
      clear_cache: false,
      output: 'tmp/metrics.csv'
    )
  end

  let(:cache) { instance_double(WttjMetrics::Data::FileCache, clear!: nil) }
  let(:data_fetcher) { instance_double(WttjMetrics::Services::DataFetcher, call: fetched_data) }
  let(:calculator) { instance_double(WttjMetrics::Metrics::Calculator, calculate_all: calculated_rows) }
  let(:csv_writer) { instance_double(WttjMetrics::Data::CsvWriter, write_rows: nil) }
  let(:summary_logger) { instance_double(WttjMetrics::Services::MetricsSummaryLogger, call: nil) }

  let(:fetched_data) do
    {
      issues: [{ id: '1' }],
      cycles: [{ id: 'c1' }],
      team_members: [{ id: 'm1' }],
      workflow_states: [{ id: 's1' }]
    }
  end

  let(:calculated_rows) do
    [
      ['2024-01-01', 'flow', 'avg_cycle_time_days', '10.5'],
      ['2024-01-01', 'issues', 'total_issues', '150']
    ]
  end

  before do
    allow(WttjMetrics::Config).to receive(:validate!)
    allow(WttjMetrics::Services::CacheFactory).to receive_messages(enabled: cache, disabled: nil)
    allow(WttjMetrics::Services::DataFetcher).to receive(:new).and_return(data_fetcher)
    allow(WttjMetrics::Metrics::Calculator).to receive(:new).and_return(calculator)
    allow(WttjMetrics::Data::CsvWriter).to receive(:new).and_return(csv_writer)
    allow(WttjMetrics::Services::MetricsSummaryLogger).to receive(:new).and_return(summary_logger)
  end

  describe '#call' do
    subject(:collector) { described_class.new(options, logger) }

    it 'validates configuration' do
      collector.call

      expect(WttjMetrics::Config).to have_received(:validate!)
    end

    it 'logs the start message with current date' do
      collector.call

      expect(logger).to have_received(:info).with(match(/🚀 Starting Linear Metrics Collection/))
    end

    it 'creates a DataFetcher with cache and logger' do
      collector.call

      expect(WttjMetrics::Services::DataFetcher).to have_received(:new).with(cache, logger)
    end

    it 'calls DataFetcher to fetch data' do
      collector.call

      expect(data_fetcher).to have_received(:call)
    end

    it 'logs metrics calculation' do
      collector.call

      expect(logger).to have_received(:info).with('🔢 Calculating metrics...')
    end

    it 'creates a Calculator with fetched data' do
      collector.call

      expect(WttjMetrics::Metrics::Calculator).to have_received(:new).with(
        [{ id: '1' }],
        [{ id: 'c1' }],
        [{ id: 'm1' }],
        [{ id: 's1' }]
      )
    end

    it 'calls calculate_all on the calculator' do
      collector.call

      expect(calculator).to have_received(:calculate_all)
    end

    it 'creates a CsvWriter with output path' do
      collector.call

      expect(WttjMetrics::Data::CsvWriter).to have_received(:new).with('tmp/metrics.csv')
    end

    it 'writes calculated rows to CSV' do
      collector.call

      expect(csv_writer).to have_received(:write_rows).with(calculated_rows)
    end

    it 'logs writing metrics with row count' do
      collector.call

      expect(logger).to have_received(:info).with(match(/📝 Writing 2 metrics to CSV/))
    end

    it 'logs success message' do
      collector.call

      expect(logger).to have_received(:info).with('✅ Metrics collected and saved successfully!')
    end

    it 'creates and calls MetricsSummaryLogger' do
      collector.call

      expect(WttjMetrics::Services::MetricsSummaryLogger).to have_received(:new).with(calculated_rows, logger)
      expect(summary_logger).to have_received(:call)
    end

    context 'when cache is enabled' do
      let(:options) do
        double('Options', cache_enabled: true, clear_cache: false, output: 'tmp/metrics.csv')
      end

      it 'uses enabled cache' do
        collector.call

        expect(WttjMetrics::Services::CacheFactory).to have_received(:enabled)
      end

      it 'does not clear cache when clear_cache is false' do
        collector.call

        expect(cache).not_to have_received(:clear!)
      end
    end

    context 'when cache is disabled' do
      let(:options) do
        double('Options', cache_enabled: false, clear_cache: false, output: 'tmp/metrics.csv')
      end

      it 'uses disabled cache (nil)' do
        collector.call

        expect(WttjMetrics::Services::CacheFactory).to have_received(:disabled)
      end

      it 'passes nil as cache to DataFetcher' do
        collector.call

        expect(WttjMetrics::Services::DataFetcher).to have_received(:new).with(nil, logger)
      end
    end

    context 'when clear_cache is true' do
      let(:options) do
        double('Options', cache_enabled: true, clear_cache: true, output: 'tmp/metrics.csv')
      end

      it 'clears the cache before fetching data' do
        collector.call

        expect(cache).to have_received(:clear!)
      end
    end

    context 'with integration flow' do
      let(:call_order) { [] }

      before do
        allow(WttjMetrics::Config).to receive(:validate!) { call_order << :validate }
        allow(logger).to receive(:info) do |msg|
          call_order << :log_start if msg.include?('🚀 Starting')
          call_order << :log_calculating if msg.include?('🔢 Calculating')
          call_order << :log_writing if msg.include?('📝 Writing')
          call_order << :log_success if msg.include?('✅ Metrics collected')
        end
        allow(data_fetcher).to receive(:call) {
          call_order << :fetch_data
          fetched_data
        }
        allow(calculator).to receive(:calculate_all) {
          call_order << :calculate
          calculated_rows
        }
        allow(csv_writer).to receive(:write_rows) { call_order << :write }
        allow(summary_logger).to receive(:call) { call_order << :log_summary }
      end

      it 'executes steps in correct order' do
        collector.call

        expect(call_order).to eq(%i[
                                   validate
                                   log_start
                                   fetch_data
                                   log_calculating
                                   calculate
                                   log_writing
                                   write
                                   log_success
                                   log_summary
                                 ])
      end
    end
  end
end
