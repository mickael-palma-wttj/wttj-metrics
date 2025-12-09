# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'

module WttjMetrics
  module Reports
    module Github
      class ReportGenerator
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
          @metrics ||= {
            avg_time_to_merge: latest_metric('avg_time_to_merge_days'),
            total_merged: latest_metric('total_merged_prs'),
            avg_reviews: latest_metric('avg_reviews_per_pr'),
            avg_comments: latest_metric('avg_comments_per_pr'),
            avg_time_to_first_review: latest_metric('avg_time_to_first_review_days'),
            avg_additions: latest_metric('avg_additions_per_pr'),
            avg_deletions: latest_metric('avg_deletions_per_pr'),
            avg_changed_files: latest_metric('avg_changed_files_per_pr'),
            avg_commits: latest_metric('avg_commits_per_pr')
          }
        end

        def history
          @history ||= {
            avg_time_to_merge: history_for('avg_time_to_merge_days'),
            total_merged: history_for('total_merged_prs'),
            avg_reviews: history_for('avg_reviews_per_pr'),
            avg_comments: history_for('avg_comments_per_pr'),
            avg_time_to_first_review: history_for('avg_time_to_first_review_days'),
            avg_additions: history_for('avg_additions_per_pr'),
            avg_deletions: history_for('avg_deletions_per_pr'),
            avg_changed_files: history_for('avg_changed_files_per_pr'),
            avg_commits: history_for('avg_commits_per_pr')
          }
        end

        def daily_breakdown
          @daily_breakdown ||= begin
            daily_data = @parser.metrics_by_category['github_daily'] || []
            grouped = daily_data.group_by { |m| m[:date] }
            sorted_dates = grouped.keys.sort

            datasets = initialize_datasets

            sorted_dates.each do |date|
              metrics = grouped[date]
              datasets[:merged] << get_value(metrics, 'merged')
              datasets[:closed] << get_value(metrics, 'closed')
              datasets[:open] << get_value(metrics, 'open')
              datasets[:avg_time_to_merge] << get_value(metrics, 'avg_time_to_merge_hours')
              datasets[:avg_reviews] << get_value(metrics, 'avg_reviews_per_pr')
              datasets[:avg_comments] << get_value(metrics, 'avg_comments_per_pr')
              datasets[:avg_additions] << get_value(metrics, 'avg_additions_per_pr')
              datasets[:avg_deletions] << get_value(metrics, 'avg_deletions_per_pr')
              datasets[:avg_time_to_first_review] << get_value(metrics, 'avg_time_to_first_review_hours')
            end

            { labels: sorted_dates, datasets: datasets }
          end
        end

        private

        def excel_report_data
          {
            today: @today,
            metrics: metrics,
            daily_breakdown: daily_breakdown,
            top_repositories: top_repositories,
            raw_data: @parser.data
          }
        end

        def top_repositories
          start_date = (Date.today - @days_to_show).to_s

          metrics = (@parser.metrics_by_category['github_repo_activity'] || [])
                    .select { |m| m[:date] >= start_date }
                    .group_by { |m| m[:metric] }

          aggregated = metrics.map do |repo_name, repo_metrics|
            {
              metric: repo_name,
              value: repo_metrics.sum { |m| m[:value] },
              date: @today
            }
          end

          aggregated.sort_by { |m| -m[:value] }.first(10)
        end

        def initialize_datasets
          {
            merged: [], closed: [], open: [],
            avg_time_to_merge: [], avg_reviews: [], avg_comments: [],
            avg_additions: [], avg_deletions: [], avg_time_to_first_review: []
          }
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
      end
    end
  end
end
