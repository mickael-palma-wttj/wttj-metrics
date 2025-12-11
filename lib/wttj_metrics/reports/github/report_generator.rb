# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'
require_relative 'weekly_aggregator'

module WttjMetrics
  module Reports
    module Github
      class ReportGenerator
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

        def initialize(csv_path, days: 90, teams: nil)
          @csv_path = csv_path
          @days_to_show = days
          @teams = teams # Unused but kept for interface consistency
          @today = Date.today.to_s
          @parser = Data::CsvParser.new(csv_path)
          @data = @parser.data
        end

        def generate_html(output_path)
          html = build_html
          File.write(output_path, html)
          puts "✅ HTML report generated: #{output_path}"
        end

        def generate_excel(output_path)
          builder = ExcelReportBuilder.new(excel_report_data)
          builder.build(output_path)
          puts "✅ Excel report generated: #{output_path}"
        end

        def metrics
          @metrics ||= METRIC_MAPPING.transform_values { |name| latest_metric(name) }
                                     .merge(deploy_frequency_daily: calculate_daily_deploy_frequency)
        end

        def history
          @history ||= METRIC_MAPPING.transform_values { |name| history_for(name) }
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

        def latest_metric(name)
          metrics_data
            .select { |m| m[:metric] == name }
            .max_by { |m| m[:date] }
            &.dig(:value) || 0
        end

        def history_for(name)
          metrics_data
            .select { |m| m[:metric] == name }
            .sort_by { |m| m[:date] }
            .map { |m| { date: m[:date], value: m[:value] } }
        end

        def metrics_data
          @parser.metrics_by_category['github'] || []
        end

        def cutoff_date
          @cutoff_date ||= (Date.today - @days_to_show).to_s
        end

        def build_html
          template_path = File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'github_report.html.erb')

          if File.exist?(template_path)
            template = ERB.new(File.read(template_path))
            template.result(binding)
          else
            build_html_fallback
          end
        end

        def build_html_fallback
          <<~HTML
            <!DOCTYPE html>
            <html>
            <head><title>GitHub Metrics - #{@today}</title></head>
            <body>
              <h1>GitHub Metrics Dashboard</h1>
              <p>Generated: #{@today}</p>
              <p>Please run with the proper template file.</p>
            </body>
            </html>
          HTML
        end

        def calculate_daily_deploy_frequency
          daily = latest_metric('deploy_frequency_daily')
          return daily if daily.nonzero?

          (latest_metric('deploy_frequency_weekly') / 7.0).round(2)
        end
      end
    end
  end
end
