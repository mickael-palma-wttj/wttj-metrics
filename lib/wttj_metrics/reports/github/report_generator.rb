# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'
require_relative 'percentile_data_builder'

module WttjMetrics
  module Reports
    module Github
      class ReportGenerator
        include Helpers::FormattingHelper

        METRIC_MAPPING = {
          avg_time_to_merge: 'avg_time_to_merge_days',
          total_merged: 'total_merged_prs',
          avg_reviews: 'avg_reviews_per_pr',
          avg_comments: 'avg_comments_per_pr',
          avg_time_to_first_review: 'avg_time_to_first_review_days',
          avg_additions: 'avg_additions_per_pr',
          avg_deletions: 'avg_deletions_per_pr',
          avg_changed_files: 'avg_changed_files_per_pr',
          avg_commits: 'avg_commits_per_pr',
          merge_rate: 'merge_rate',
          avg_time_to_approval: 'avg_time_to_approval_days',
          avg_rework_cycles: 'avg_rework_cycles',
          unreviewed_pr_rate: 'unreviewed_pr_rate',
          ci_success_rate: 'ci_success_rate',
          deploy_frequency: 'deploy_frequency_weekly',
          hotfix_rate: 'hotfix_rate',
          time_to_green: 'time_to_green_hours'
        }.freeze

        DAILY_METRIC_MAPPING = {
          merged: 'merged', closed: 'closed', open: 'open',
          avg_time_to_merge: 'avg_time_to_merge_hours',
          avg_reviews: 'avg_reviews_per_pr',
          avg_comments: 'avg_comments_per_pr',
          avg_additions: 'avg_additions_per_pr',
          avg_deletions: 'avg_deletions_per_pr',
          avg_time_to_first_review: 'avg_time_to_first_review_days',
          merge_rate: 'merge_rate',
          avg_time_to_approval: 'avg_time_to_approval_days',
          avg_rework_cycles: 'avg_rework_cycles',
          unreviewed_pr_rate: 'unreviewed_pr_rate',
          ci_success_rate: 'ci_success_rate',
          deploy_frequency: 'releases_count',
          hotfix_rate: 'hotfix_rate',
          time_to_green: 'avg_time_to_green_hours'
        }.freeze

        attr_reader :data, :days_to_show, :today

        def initialize(csv_path, days: 90, teams: nil, teams_config: nil)
          @csv_path = csv_path
          @days_to_show = days
          @teams = teams # Unused but kept for interface consistency
          @teams_config = teams_config
          @today = Date.today.to_s
          @parser = Data::CsvParser.new(csv_path)
          @data = @parser.data
        end

        def generate_html(output_path)
          HtmlReportBuilder.new(self).build(output_path)
        end

        def template_binding
          binding
        end

        def generate_excel(output_path)
          builder = ExcelReportBuilder.new(excel_report_data)
          builder.build(output_path)
          puts "✅ Excel report generated: #{output_path}"
        end

        def metrics
          @metrics ||= begin
            calculator = MetricsCalculator.new(metrics_data('github'))
            METRIC_MAPPING.transform_values { |name| calculator.latest(name) }
                          .merge(deploy_frequency_daily: calculate_daily_deploy_frequency)
          end
        end

        def history
          @history ||= begin
            calculator = MetricsCalculator.new(metrics_data('github'))
            METRIC_MAPPING.transform_values { |name| calculator.history(name) }
          end
        end

        def daily_breakdown
          @daily_breakdown ||= begin
            grouped_data = group_daily_data
            sorted_dates = grouped_data.keys.sort
            datasets = build_datasets(grouped_data, sorted_dates)

            { labels: sorted_dates, datasets: datasets }
          end
        end

        def weekly_breakdown
          @weekly_breakdown ||= begin
            daily_data = @parser.metrics_by_category['github_daily'] || []
            WeeklyAggregator.new(daily_data).aggregate
          end
        end

        def percentile_data
          @percentile_data ||= PercentileDataBuilder.new(@parser, cutoff_date: cutoff_date).all_percentile_data
        end

        def team_metrics
          @team_metrics ||= begin
            teams = TeamService.new(@parser, @teams_config).resolve_teams

            teams.each_with_object({}) do |team_name, hash|
              category = "github:#{team_name}"
              calculator = MetricsCalculator.new(metrics_data(category))

              hash[team_name] = {
                metrics: METRIC_MAPPING.transform_values { |name| calculator.latest(name) },
                history: METRIC_MAPPING.transform_values { |name| calculator.history(name) },
                daily_breakdown: daily_breakdown_for(team_name)
              }
            end
          end
        end

        def commit_activity
          @commit_activity ||= begin
            data = @parser.metrics_by_category['github_commit_activity'] || []
            grid = Array.new(7) { Array.new(24) { { count: 0, authors: {} } } }

            data.each do |row|
              # row[:metric] is "wday_hour" (e.g. "1_14")
              wday, hour = row[:metric].split('_').map(&:to_i)

              # wday: 0=Sunday, 1=Monday...
              # We want Monday=0 for display, so (wday - 1) % 7
              display_wday = (wday - 1) % 7
              hour = hour.to_i

              # Parse JSON value if it's a string, otherwise handle legacy integer
              begin
                parsed_value = if row[:value].is_a?(String)
                                 JSON.parse(row[:value])
                               else
                                 { 'count' => row[:value].to_i,
                                   'authors' => {} }
                               end
              rescue JSON::ParserError
                parsed_value = { 'count' => row[:value].to_i, 'authors' => {} }
              end

              # Ensure we have a hash structure
              parsed_value = { 'count' => parsed_value.to_i, 'authors' => {} } if parsed_value.is_a?(Numeric)

              grid[display_wday][hour][:count] += parsed_value['count'].to_i

              next unless parsed_value['authors']

              parsed_value['authors'].each do |author, count|
                grid[display_wday][hour][:authors][author] ||= 0
                grid[display_wday][hour][:authors][author] += count
              end
            end
            grid
          end
        end

        private

        def excel_report_data
          {
            today: @today,
            metrics: metrics,
            daily_breakdown: daily_breakdown,
            top_repositories: top_repositories,
            top_contributors: top_contributors,
            raw_data: @parser.data
          }
        end

        def top_repositories
          top_metrics_for('github_repo_activity')
        end

        def top_contributors
          top_metrics_for('github_contributor_activity')
        end

        def group_daily_data
          (@parser.metrics_by_category['github_daily'] || []).group_by { |m| m[:date] }
        end

        def daily_breakdown_for(team_name)
          category = "github:#{team_name}_daily"
          grouped_data = (@parser.metrics_by_category[category] || []).group_by { |m| m[:date] }
          sorted_dates = grouped_data.keys.sort
          datasets = build_datasets(grouped_data, sorted_dates)

          { labels: sorted_dates, datasets: datasets }
        end

        def build_datasets(grouped_data, dates)
          datasets = Hash.new { |h, k| h[k] = [] }
          dates.each do |date|
            metrics = grouped_data[date]
            DAILY_METRIC_MAPPING.each do |key, metric_name|
              datasets[key] << get_value(metrics, metric_name)
            end
          end
          datasets
        end

        def top_metrics_for(category)
          metrics = filter_and_group_metrics(category)
          aggregate_and_sort_metrics(metrics)
        end

        def filter_and_group_metrics(category)
          (@parser.metrics_by_category[category] || [])
            .select { |m| m[:date] >= cutoff_date }
            .group_by { |m| m[:metric] }
        end

        def aggregate_and_sort_metrics(grouped_metrics)
          aggregated = grouped_metrics.map do |name, metrics|
            { metric: name, value: metrics.sum { |m| m[:value] }, date: @today }
          end

          aggregated.sort_by { |m| -m[:value] }.first(10)
        end

        def get_value(metrics, name)
          metrics&.find { |m| m[:metric] == name }&.dig(:value) || 0
        end

        def metrics_data(category = 'github')
          @parser.metrics_by_category[category] || []
        end

        def cutoff_date
          @cutoff_date ||= (Date.today - @days_to_show).to_s
        end

        def calculate_daily_deploy_frequency
          calculator = MetricsCalculator.new(metrics_data('github'))
          daily = calculator.latest('deploy_frequency_daily')
          return daily if daily.nonzero?

          (calculator.latest('deploy_frequency_weekly') / 7.0).round(2)
        end
      end
    end
  end
end
