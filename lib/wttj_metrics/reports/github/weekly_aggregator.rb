# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Github
      # Aggregates daily GitHub metrics into weekly data
      class WeeklyAggregator
        METRIC_CALCULATIONS = {
          merged: ->(c) { c.sum('merged') },
          closed: ->(c) { c.sum('closed') },
          open: ->(c) { c.last_value('open') },
          avg_time_to_merge: ->(c) { c.weighted_avg('avg_time_to_merge_hours', 'merged') },
          avg_reviews: ->(c) { c.weighted_avg('avg_reviews_per_pr', 'created') },
          avg_comments: ->(c) { c.weighted_avg('avg_comments_per_pr', 'created') },
          avg_additions: ->(c) { c.weighted_avg('avg_additions_per_pr', 'created') },
          avg_deletions: ->(c) { c.weighted_avg('avg_deletions_per_pr', 'created') },
          avg_time_to_first_review: ->(c) { c.simple_avg('avg_time_to_first_review_days') },
          merge_rate: lambda(&:merge_rate),
          avg_time_to_approval: ->(c) { c.simple_avg('avg_time_to_approval_days') },
          avg_rework_cycles: ->(c) { c.weighted_avg('avg_rework_cycles', 'created') },
          unreviewed_pr_rate: ->(c) { c.rate_from_daily('unreviewed_pr_rate', 'created') },
          ci_success_rate: ->(c) { c.rate_from_daily('ci_success_rate', 'created') },
          deploy_frequency: ->(c) { c.sum('releases_count') },
          hotfix_rate: ->(c) { c.rate('hotfix_count', 'releases_count') },
          time_to_green: ->(c) { c.simple_avg('avg_time_to_green_hours') }
        }.freeze

        def initialize(daily_data)
          @daily_data = daily_data
        end

        def aggregate
          grouped_by_week = group_data_by_week
          sorted_weeks = grouped_by_week.keys.sort
          datasets = initialize_datasets

          sorted_weeks.each do |year, week|
            metrics_in_week = grouped_by_week[[year, week]]
            process_week(datasets, metrics_in_week)
          end

          {
            labels: generate_labels(sorted_weeks),
            datasets: datasets
          }
        end

        private

        def group_data_by_week
          @daily_data.group_by do |m|
            date = Date.parse(m[:date])
            [date.cwyear, date.cweek]
          end
        end

        def initialize_datasets
          METRIC_CALCULATIONS.keys.each_with_object({}) { |k, h| h[k] = [] }
        end

        def process_week(datasets, metrics_in_week)
          calculator = WeekCalculator.new(metrics_in_week)
          METRIC_CALCULATIONS.each do |key, calculation|
            datasets[key] << calculation.call(calculator)
          end
        end

        def generate_labels(sorted_weeks)
          sorted_weeks.map do |year, week|
            Date.commercial(year, week, 1).to_s
          end
        end

        # Helper class to calculate metrics for a single week
        class WeekCalculator
          def initialize(metrics)
            @metrics = metrics
            @by_name = metrics.group_by { |m| m[:metric] }
            @by_date = metrics.group_by { |m| m[:date] }
          end

          def sum(name)
            @by_name[name]&.sum { |m| m[:value] } || 0
          end

          def last_value(name)
            last_day = @metrics.map { |m| m[:date] }.max
            last_day_metrics = @metrics.select { |m| m[:date] == last_day }
            last_day_metrics.find { |m| m[:metric] == name }&.dig(:value) || 0
          end

          def weighted_avg(avg_name, weight_name)
            total_val, total_weight = @by_date.values.reduce([0, 0]) do |(sum_val, sum_weight), metrics|
              val = get_value(metrics, avg_name)
              weight = get_value(metrics, weight_name)
              [sum_val + (val * weight), sum_weight + weight]
            end

            total_weight.positive? ? (total_val / total_weight).round(2) : 0
          end

          def simple_avg(name)
            values = @by_name[name]&.map { |m| m[:value] } || []
            values.any? ? (values.sum / values.size).round(2) : 0
          end

          def rate(numerator_name, denominator_name)
            numerator = sum(numerator_name)
            denominator = sum(denominator_name)
            denominator.positive? ? (numerator.to_f / denominator * 100).round(2) : 0
          end

          def rate_from_daily(rate_name, base_name)
            total_base = 0
            total_target = 0

            @by_date.each_value do |daily_metrics|
              rate = get_value(daily_metrics, rate_name)
              base = get_value(daily_metrics, base_name)
              target = (rate * base / 100.0)
              total_base += base
              total_target += target
            end

            total_base.positive? ? (total_target / total_base * 100).round(2) : 0
          end

          def merge_rate
            total_merged = sum('merged')
            total_closed = sum('closed')
            total_processed = total_merged + total_closed
            total_processed.positive? ? (total_merged.to_f / total_processed * 100).round(2) : 0
          end

          private

          def get_value(metrics, name)
            metrics.find { |m| m[:metric] == name }&.dig(:value) || 0
          end
        end
      end
    end
  end
end
