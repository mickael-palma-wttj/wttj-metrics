# frozen_string_literal: true

module WttjMetrics
  module Services
    # Orchestrates metrics collection from Linear API
    class MetricsCollector
      def initialize(options, logger)
        @options = options
        @logger = logger
      end

      def call
        validate_config
        log_start
        data = fetch_data
        rows = calculate_metrics(data)
        write_results(rows)
        log_summary(rows)
      end

      private

      attr_reader :options, :logger

      def validate_config
        Config.validate!
      end

      def log_start
        logger.info "🚀 Starting Linear Metrics Collection - #{Date.today}"
      end

      def fetch_data
        DataFetcher.new(cache_strategy, logger).call
      end

      def cache_strategy
        cache = options.cache_enabled ? CacheFactory.enabled : CacheFactory.disabled
        cache&.clear! if options.clear_cache
        cache
      end

      def calculate_metrics(data)
        logger.info '🔢 Calculating metrics...'
        calculator = Metrics::Calculator.new(
          data[:issues],
          data[:cycles],
          data[:team_members],
          data[:workflow_states]
        )
        calculator.calculate_all
      end

      def write_results(rows)
        logger.info "📝 Writing #{rows.size} metrics to CSV: #{options.output}"
        Data::CsvWriter.new(options.output).write_rows(rows)
        logger.info '✅ Metrics collected and saved successfully!'
      end

      def log_summary(rows)
        MetricsSummaryLogger.new(rows, logger).call
      end
    end
  end
end
