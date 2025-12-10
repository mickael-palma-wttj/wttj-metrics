# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Github
      # Aggregates daily GitHub metrics into weekly data
      class WeeklyAggregator
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
          {
            merged: [], closed: [], open: [],
            avg_time_to_merge: [], avg_reviews: [], avg_comments: [],
            avg_additions: [], avg_deletions: [], avg_time_to_first_review: [],
            merge_rate: [], avg_time_to_approval: [], avg_rework_cycles: [],
            unreviewed_pr_rate: [], ci_success_rate: [], deploy_frequency: [],
            hotfix_rate: [], time_to_green: []
          }
        end

        def process_week(datasets, metrics_in_week)
          calculator = WeekCalculator.new(metrics_in_week)

          datasets[:merged] << calculator.sum('merged')
          datasets[:closed] << calculator.sum('closed')
          datasets[:open] << calculator.last_value('open')

          datasets[:avg_time_to_merge] << calculator.weighted_avg('avg_time_to_merge_hours', 'merged')
          datasets[:avg_reviews] << calculator.weighted_avg('avg_reviews_per_pr', 'created')
          datasets[:avg_comments] << calculator.weighted_avg('avg_comments_per_pr', 'created')
          datasets[:avg_additions] << calculator.weighted_avg('avg_additions_per_pr', 'created')
          datasets[:avg_deletions] << calculator.weighted_avg('avg_deletions_per_pr', 'created')
          datasets[:avg_time_to_first_review] << calculator.simple_avg('avg_time_to_first_review_days')

          datasets[:merge_rate] << calculator.merge_rate

          datasets[:avg_time_to_approval] << calculator.simple_avg('avg_time_to_approval_days')
          datasets[:avg_rework_cycles] << calculator.weighted_avg('avg_rework_cycles', 'created')
          datasets[:unreviewed_pr_rate] << calculator.rate_from_daily('unreviewed_pr_rate', 'created')
          datasets[:ci_success_rate] << calculator.rate_from_daily('ci_success_rate', 'created')
          datasets[:deploy_frequency] << calculator.sum('releases_count')
          datasets[:hotfix_rate] << calculator.rate_from_daily('hotfix_rate', 'releases_count')
          datasets[:time_to_green] << calculator.simple_avg('avg_time_to_green_hours')
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
            total_weight = 0
            total_value = 0

            @by_date.each_value do |daily_metrics|
              avg = daily_metrics.find { |m| m[:metric] == avg_name }&.dig(:value) || 0
              weight = daily_metrics.find { |m| m[:metric] == weight_name }&.dig(:value) || 0
              total_value += avg * weight
              total_weight += weight
            end

            total_weight.positive? ? (total_value / total_weight).round(2) : 0
          end

          def simple_avg(name)
            values = @by_name[name]&.map { |m| m[:value] } || []
            values.any? ? (values.sum / values.size).round(2) : 0
          end

          def rate_from_daily(rate_name, base_name)
            total_base = 0
            total_target = 0

            @by_date.each_value do |daily_metrics|
              rate = daily_metrics.find { |m| m[:metric] == rate_name }&.dig(:value) || 0
              base = daily_metrics.find { |m| m[:metric] == base_name }&.dig(:value) || 0
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
        end
      end
    end
  end
end
