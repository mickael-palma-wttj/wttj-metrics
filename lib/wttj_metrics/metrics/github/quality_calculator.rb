# frozen_string_literal: true

require 'date'
require 'time'

module WttjMetrics
  module Metrics
    module Github
      class QualityCalculator
        def initialize(pull_requests, releases)
          @pull_requests = pull_requests
          @releases = releases
        end

        def calculate
          {
            ci_success_rate: calculate_ci_success_rate,
            deploy_frequency_weekly: calculate_deploy_frequency,
            deploy_frequency_daily: calculate_deploy_frequency_daily,
            hotfix_rate: calculate_hotfix_rate,
            time_to_green_hours: calculate_time_to_green
          }
        end

        def to_rows
          stats = calculate
          date = Date.today.to_s
          [
            [date, 'github', 'ci_success_rate', stats[:ci_success_rate]],
            [date, 'github', 'deploy_frequency_weekly', stats[:deploy_frequency_weekly]],
            [date, 'github', 'deploy_frequency_daily', stats[:deploy_frequency_daily]],
            [date, 'github', 'hotfix_rate', stats[:hotfix_rate]],
            [date, 'github', 'time_to_green_hours', stats[:time_to_green_hours]]
          ]
        end

        private

        def calculate_ci_success_rate
          merged_prs = @pull_requests.select { |pr| pr[:state] == 'MERGED' }
          return 0.0 if merged_prs.empty?

          success_count = merged_prs.count do |pr|
            # Check statusCheckRollup of the last commit
            # We use lastCommit alias in GraphQL query
            commits = pr.dig(:lastCommit, :nodes)
            next false unless commits&.any?

            last_commit = commits.last[:commit]
            status = last_commit.dig(:statusCheckRollup, :state)
            status == 'SUCCESS'
          end

          (success_count.to_f / merged_prs.size * 100).round(2)
        end

        def calculate_deploy_frequency
          return 0.0 if @releases.empty?

          # Calculate releases per week
          # We have releases from the last X days (default 90)

          # Sort releases by date
          sorted_releases = @releases.sort_by { |r| r['created_at'] }
          first_date = Date.parse(sorted_releases.first['created_at'].to_s)
          last_date = Date.today

          days_diff = (last_date - first_date).to_i
          weeks = [days_diff / 7.0, 1.0].max

          (@releases.size / weeks).round(2)
        end

        def calculate_deploy_frequency_daily
          return 0.0 if @releases.empty?

          # Sort releases by date
          sorted_releases = @releases.sort_by { |r| r['created_at'] }
          first_date = Date.parse(sorted_releases.first['created_at'].to_s)
          last_date = Date.today

          days_diff = (last_date - first_date).to_i
          days = [days_diff, 1.0].max

          (@releases.size.to_f / days).round(2)
        end

        def calculate_hotfix_rate
          return 0.0 if @releases.empty?

          hotfix_count = @releases.count do |r|
            name = r['name'] || ''
            tag = r['tag_name'] || ''
            name.downcase.include?('hotfix') || tag.downcase.include?('hotfix')
          end

          (hotfix_count.to_f / @releases.size * 100).round(2)
        end

        def calculate_time_to_green
          merged_prs = @pull_requests.select { |pr| pr[:state] == 'MERGED' }
          return 0.0 if merged_prs.empty?

          times = merged_prs.filter_map do |pr|
            commits = pr.dig(:lastCommit, :nodes)
            next nil unless commits&.any?

            last_commit = commits.last[:commit]
            check_suites = last_commit.dig(:checkSuites, :nodes)
            next nil unless check_suites&.any?

            # Find the latest successful check suite
            successful_suites = check_suites.select { |cs| cs[:conclusion] == 'SUCCESS' }
            next nil if successful_suites.empty?

            latest_suite = successful_suites.max_by { |cs| cs[:updatedAt] }
            next nil unless latest_suite

            committed_date = last_commit[:committedDate]
            next nil unless committed_date

            committed_at = Time.parse(committed_date)
            suite_updated_at = Time.parse(latest_suite[:updatedAt])

            (suite_updated_at - committed_at) / 3600.0 # in hours
          end

          return 0.0 if times.empty?

          (times.sum / times.size).round(2)
        end
      end
    end
  end
end
