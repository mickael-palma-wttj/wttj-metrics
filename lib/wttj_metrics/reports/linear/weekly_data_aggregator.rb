# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Linear
      # Aggregates timeseries data into weekly buckets with percentages
      # Single Responsibility: Weekly data aggregation logic
      class WeeklyDataAggregator
        include Helpers::DateHelper
        include Helpers::FormattingHelper

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
            result[:labels] << format_week_label(week)
            result[:values] << sum_for_dates(dates, by_date)
          end

          result
        end

        private

        def to_date_hash(metrics)
          metrics.to_h { |m| [m[:date], m[:value].to_i] }
        end

        def group_by_week(dates)
          dates.uniq.sort.group_by do |date|
            d = Date.parse(date)
            d - d.wday + 1 # Group by Monday
          end
        end

        def build_weekly_result(weekly_data, by_date_a, by_date_b, labels)
          result = initialize_result_hash(labels)

          weekly_data.sort.each do |week, dates|
            sums = calculate_sums(dates, by_date_a, by_date_b)
            update_result(result, week, sums, labels)
          end

          result
        end

        def initialize_result_hash(labels)
          {
            labels: [],
            "#{labels[0]}_raw": [],
            "#{labels[1]}_raw": [],
            "#{labels[0]}_pct": [],
            "#{labels[1]}_pct": []
          }
        end

        def calculate_sums(dates, by_date_a, by_date_b)
          [
            sum_for_dates(dates, by_date_a),
            sum_for_dates(dates, by_date_b)
          ]
        end

        def update_result(result, week, sums, labels)
          sum_a, sum_b = sums
          total = sum_a + sum_b

          result[:labels] << format_week_label(week)
          result[:"#{labels[0]}_raw"] << sum_a
          result[:"#{labels[1]}_raw"] << sum_b
          result[:"#{labels[0]}_pct"] << format_percentage(sum_a, total)
          result[:"#{labels[1]}_pct"] << format_percentage(sum_b, total)
        end

        def sum_for_dates(dates, by_date)
          dates.sum { |date| by_date[date] || 0 }
        end

        def format_week_label(week)
          week.strftime('%b %d')
        end
      end
    end
  end
end
