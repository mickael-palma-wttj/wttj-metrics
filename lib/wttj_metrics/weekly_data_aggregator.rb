# frozen_string_literal: true

require 'date'

module WttjMetrics
  # Aggregates timeseries data into weekly buckets with percentages
  # Single Responsibility: Weekly data aggregation logic
  class WeeklyDataAggregator
    def initialize(cutoff_date)
      @cutoff_date = cutoff_date
    end

    # Aggregates two metrics into weekly comparison data (e.g., created vs completed)
    # Returns a hash with labels, raw values, and percentages for each metric
    def aggregate_pair(metric_a_data, metric_b_data, labels: %i[a b])
      by_date_a = to_date_hash(metric_a_data)
      by_date_b = to_date_hash(metric_b_data)

      weekly_data = group_by_week(by_date_a.keys + by_date_b.keys)

      build_weekly_result(weekly_data, by_date_a, by_date_b, labels)
    end

    # Aggregates a single metric into weekly buckets
    # Returns a hash with labels and values
    def aggregate_single(metric_data)
      by_date = to_date_hash(metric_data)
      weekly_data = group_by_week(by_date.keys)

      result = { labels: [], values: [] }

      weekly_data.sort.each do |week, dates|
        result[:labels] << format_week_label(week, dates)
        result[:values] << sum_for_dates(dates, by_date)
      end

      result
    end

    private

    def to_date_hash(metrics)
      metrics.to_h { |m| [m[:date], m[:value].to_i] }
    end

    def group_by_week(dates)
      # Group by Monday of each week to handle year boundaries correctly
      dates.uniq.sort.group_by do |d|
        date = Date.parse(d)
        monday = date - ((date.wday - 1) % 7)
        monday.to_s
      end
    end

    def build_weekly_result(weekly_data, by_date_a, by_date_b, labels)
      result = {
        labels: [],
        "#{labels[0]}_raw": [],
        "#{labels[1]}_raw": [],
        "#{labels[0]}_pct": [],
        "#{labels[1]}_pct": []
      }

      weekly_data.sort.each do |week, dates|
        result[:labels] << format_week_label(week, dates)

        sum_a = sum_for_dates(dates, by_date_a)
        sum_b = sum_for_dates(dates, by_date_b)
        total = sum_a + sum_b

        result[:"#{labels[0]}_raw"] << sum_a
        result[:"#{labels[1]}_raw"] << sum_b
        result[:"#{labels[0]}_pct"] << calculate_percentage(sum_a, total)
        result[:"#{labels[1]}_pct"] << calculate_percentage(sum_b, total)
      end

      result
    end

    def format_week_label(week, _dates)
      # week is now the Monday date string (e.g., "2024-12-30")
      Date.parse(week).strftime('%b %d')
    end

    def sum_for_dates(dates, by_date)
      dates.sum { |d| by_date[d] || 0 }
    end

    def calculate_percentage(value, total)
      return 0 if total.zero?

      ((value.to_f / total) * 100).round(1)
    end
  end
end
