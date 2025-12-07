# frozen_string_literal: true

module WttjMetrics
  module Services
    # Logs metrics summary
    class MetricsSummaryLogger
      SUMMARY_CATEGORIES = %w[flow cycle_metrics team issues].freeze
      MAX_SUMMARY_ITEMS = 6

      def initialize(rows, logger)
        @rows = rows
        @logger = logger
      end

      def call
        logger.info "\nMetrics Summary:"
        summary_rows.each { |row| logger.info "  - #{row[2]}: #{row[3]}" }
      end

      private

      attr_reader :rows, :logger

      def summary_rows
        rows
          .select { |r| SUMMARY_CATEGORIES.include?(r[1]) }
          .first(MAX_SUMMARY_ITEMS)
      end
    end
  end
end
