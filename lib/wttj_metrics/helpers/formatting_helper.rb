# frozen_string_literal: true

module WttjMetrics
  module Helpers
    # Common formatting helpers for display values
    module FormattingHelper
      PERCENTAGE_MULTIPLIER = 100

      def format_percentage(value, total)
        return 0 if total.zero?

        ((value.to_f / total) * PERCENTAGE_MULTIPLIER).round
      end

      def format_with_unit(value, unit)
        "#{value}#{unit}"
      end

      def humanize_metric_name(name)
        name.to_s
            .tr('_', ' ')
            .gsub(/\s+/, ' ')
            .strip
            .capitalize
      end

      def format_count_display(completed, total)
        "#{completed}/#{total}"
      end

      def format_points_display(points)
        "#{points} pts"
      end
    end
  end
end
