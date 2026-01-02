# frozen_string_literal: true

module WttjMetrics
  module Values
    # Value object for collect command options
    class CollectOptions
      attr_reader :output, :cache_enabled, :clear_cache, :sources, :days, :start_date, :end_date

      def initialize(options_hash)
        @output = options_hash[:output]
        @cache_enabled = options_hash[:cache]
        @clear_cache = options_hash[:clear_cache]
        @sources = options_hash[:sources] || ['linear']
        @start_date = parse_date(options_hash[:start_date])
        @end_date = parse_date(options_hash[:end_date]) || Date.today
        @days = calculate_days(options_hash[:days])
      end

      private

      def parse_date(date_string)
        return nil unless date_string

        Date.parse(date_string)
      end

      def calculate_days(default_days)
        return default_days || 90 unless @start_date

        (@end_date - @start_date).to_i
      end
    end
  end
end
