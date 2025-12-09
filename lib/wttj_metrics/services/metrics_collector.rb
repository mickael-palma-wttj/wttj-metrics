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
        return if data.empty?

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
        logger.info "🚀 Starting Metrics Collection (#{options.sources.join(', ')}) - #{Date.today}"
      end

      def fetch_data
        data = {}

        data.merge!(Linear::DataFetcher.new(cache_strategy, logger).call) if options.sources.include?('linear')

        if options.sources.include?('github')
          if ENV['GITHUB_TOKEN'] && (ENV['GITHUB_REPO'] || ENV.fetch('GITHUB_ORG', nil))
            data.merge!(Github::DataFetcher.new(logger, options.days).call)
          else
            logger.warn '⚠️  Skipping GitHub: GITHUB_TOKEN or (GITHUB_REPO/GITHUB_ORG) not set'
          end
        end

        data
      end

      def cache_strategy
        cache = options.cache_enabled ? CacheFactory.enabled : CacheFactory.disabled
        cache&.clear! if options.clear_cache
        cache
      end

      def calculate_metrics(data)
        logger.info '🔢 Calculating metrics...'
        rows = []

        if options.sources.include?('linear') && data[:issues]
          calculator = Metrics::Linear::Calculator.new(
            data[:issues],
            data[:cycles],
            data[:team_members],
            data[:workflow_states]
          )
          rows.concat(calculator.calculate_all)
        end

        if options.sources.include?('github') && data[:pull_requests]
          github_rows = Metrics::Github::Calculator.new(data[:pull_requests]).calculate_all
          rows.concat(github_rows)
        end

        rows
      end

      def write_results(rows)
        logger.info "📝 Writing #{rows.size} metrics to CSV: #{options.output}"
        DirectoryPreparer.ensure_exists(options.output)
        Data::CsvWriter.new(options.output).write_rows(rows)
        logger.info '✅ Metrics collected and saved successfully!'
      end

      def log_summary(rows)
        MetricsSummaryLogger.new(rows, logger).call
      end
    end
  end
end
