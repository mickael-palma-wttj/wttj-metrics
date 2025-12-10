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
            avg_commits: latest_metric('avg_commits_per_pr'),
            merge_rate: latest_metric('merge_rate'),
            avg_time_to_approval: latest_metric('avg_time_to_approval_days'),
            avg_rework_cycles: latest_metric('avg_rework_cycles'),
            unreviewed_pr_rate: latest_metric('unreviewed_pr_rate'),
            ci_success_rate: latest_metric('ci_success_rate'),
            deploy_frequency: latest_metric('deploy_frequency_weekly'),
            deploy_frequency_daily: calculate_daily_deploy_frequency,
            hotfix_rate: latest_metric('hotfix_rate'),
            time_to_green: latest_metric('time_to_green_hours')
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
            avg_commits: history_for('avg_commits_per_pr'),
            merge_rate: history_for('merge_rate'),
            avg_time_to_approval: history_for('avg_time_to_approval_days'),
            avg_rework_cycles: history_for('avg_rework_cycles'),
            unreviewed_pr_rate: history_for('unreviewed_pr_rate'),
            ci_success_rate: history_for('ci_success_rate'),
            deploy_frequency: history_for('deploy_frequency_weekly'),
            hotfix_rate: history_for('hotfix_rate'),
            time_to_green: history_for('time_to_green_hours')
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
              datasets[:avg_time_to_first_review] << get_value(metrics, 'avg_time_to_first_review_days')
              datasets[:merge_rate] << get_value(metrics, 'merge_rate')
              datasets[:avg_time_to_approval] << get_value(metrics, 'avg_time_to_approval_days')
              datasets[:avg_rework_cycles] << get_value(metrics, 'avg_rework_cycles')
              datasets[:unreviewed_pr_rate] << get_value(metrics, 'unreviewed_pr_rate')
              datasets[:ci_success_rate] << get_value(metrics, 'ci_success_rate')
              datasets[:deploy_frequency] << get_value(metrics, 'releases_count')
              datasets[:hotfix_rate] << get_value(metrics, 'hotfix_rate')
              datasets[:time_to_green] << get_value(metrics, 'avg_time_to_green_hours')
            end

            { labels: sorted_dates, datasets: datasets }
          end
        end

        def weekly_breakdown
          @weekly_breakdown ||= begin
            daily_data = @parser.metrics_by_category['github_daily'] || []
            grouped_by_week = daily_data.group_by do |m|
              date = Date.parse(m[:date])
              [date.cwyear, date.cweek]
            end

            sorted_weeks = grouped_by_week.keys.sort
            datasets = initialize_datasets

            sorted_weeks.each do |year, week|
              metrics_in_week = grouped_by_week[[year, week]]
              metrics_by_name = metrics_in_week.group_by { |m| m[:metric] }

              sum_metric = ->(name) { metrics_by_name[name]&.sum { |m| m[:value] } || 0 }

              weighted_avg = lambda do |avg_name, weight_name|
                total_weight = 0
                total_value = 0
                by_date = metrics_in_week.group_by { |m| m[:date] }
                by_date.each do |_date, daily_metrics|
                  avg = daily_metrics.find { |m| m[:metric] == avg_name }&.dig(:value) || 0
                  weight = daily_metrics.find { |m| m[:metric] == weight_name }&.dig(:value) || 0
                  total_value += avg * weight
                  total_weight += weight
                end
                total_weight > 0 ? (total_value / total_weight).round(2) : 0
              end

              simple_avg = lambda do |name|
                values = metrics_by_name[name]&.map { |m| m[:value] } || []
                values.any? ? (values.sum / values.size).round(2) : 0
              end

              calc_rate_from_daily = lambda do |rate_name, base_name|
                total_base = 0
                total_target = 0
                by_date = metrics_in_week.group_by { |m| m[:date] }
                by_date.each do |_date, daily_metrics|
                  rate = daily_metrics.find { |m| m[:metric] == rate_name }&.dig(:value) || 0
                  base = daily_metrics.find { |m| m[:metric] == base_name }&.dig(:value) || 0
                  target = (rate * base / 100.0)
                  total_base += base
                  total_target += target
                end
                total_base > 0 ? (total_target / total_base * 100).round(2) : 0
              end

              datasets[:merged] << sum_metric.call('merged')
              datasets[:closed] << sum_metric.call('closed')

              last_day = metrics_in_week.map { |m| m[:date] }.max
              last_day_metrics = metrics_in_week.select { |m| m[:date] == last_day }
              datasets[:open] << get_value(last_day_metrics, 'open')

              datasets[:avg_time_to_merge] << weighted_avg.call('avg_time_to_merge_hours', 'merged')
              datasets[:avg_reviews] << weighted_avg.call('avg_reviews_per_pr', 'created')
              datasets[:avg_comments] << weighted_avg.call('avg_comments_per_pr', 'created')
              datasets[:avg_additions] << weighted_avg.call('avg_additions_per_pr', 'created')
              datasets[:avg_deletions] << weighted_avg.call('avg_deletions_per_pr', 'created')
              datasets[:avg_time_to_first_review] << simple_avg.call('avg_time_to_first_review_days')

              total_merged = sum_metric.call('merged')
              total_closed = sum_metric.call('closed')
              datasets[:merge_rate] << (total_merged + total_closed > 0 ? (total_merged.to_f / (total_merged + total_closed) * 100).round(2) : 0)

              datasets[:avg_time_to_approval] << simple_avg.call('avg_time_to_approval_days')
              datasets[:avg_rework_cycles] << weighted_avg.call('avg_rework_cycles', 'created')
              datasets[:unreviewed_pr_rate] << calc_rate_from_daily.call('unreviewed_pr_rate', 'created')
              datasets[:ci_success_rate] << calc_rate_from_daily.call('ci_success_rate', 'created')
              datasets[:deploy_frequency] << sum_metric.call('releases_count')
              datasets[:hotfix_rate] << calc_rate_from_daily.call('hotfix_rate', 'releases_count')
              datasets[:time_to_green] << simple_avg.call('avg_time_to_green_hours')
            end

            labels = sorted_weeks.map do |year, week|
              Date.commercial(year, week, 1).to_s
            end

            { labels: labels, datasets: datasets }
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

        def top_contributors
          start_date = (Date.today - @days_to_show).to_s

          metrics = (@parser.metrics_by_category['github_contributor_activity'] || [])
                    .select { |m| m[:date] >= start_date }
                    .group_by { |m| m[:metric] }

          aggregated = metrics.map do |author, author_metrics|
            {
              metric: author,
              value: author_metrics.sum { |m| m[:value] },
              date: @today
            }
          end

          aggregated.sort_by { |m| -m[:value] }.first(10)
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

        def calculate_daily_deploy_frequency
          daily = latest_metric('deploy_frequency_daily')
          return daily if daily.nonzero?

          (latest_metric('deploy_frequency_weekly') / 7.0).round(2)
        end
      end
    end
  end
end
