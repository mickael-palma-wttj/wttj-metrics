# frozen_string_literal: true

require 'date'
require 'time'

module WttjMetrics
  module Metrics
    module Github
      class TimeseriesCalculator
        def initialize(pull_requests, releases = [])
          @pull_requests = pull_requests
          @releases = releases || []
        end

        def to_rows
          daily_stats.flat_map do |date, stats|
            created_count = stats[:created]
            avg_merge_time = calculate_average(stats[:total_merge_time], stats[:merged], 3600.0)
            avg_reviews = calculate_average(stats[:total_reviews], created_count)
            avg_comments = calculate_average(stats[:total_comments], created_count)
            avg_additions = calculate_average(stats[:total_additions], created_count)
            avg_deletions = calculate_average(stats[:total_deletions], created_count)
            avg_time_to_first_review = calculate_average(
              stats[:total_time_to_first_review],
              stats[:count_with_reviews],
              86_400.0
            )
            avg_time_to_approval = calculate_average(
              stats[:total_time_to_approval],
              stats[:count_with_approval],
              86_400.0
            )
            avg_rework_cycles = calculate_average(stats[:total_rework_cycles], created_count)
            avg_time_to_green = calculate_average(stats[:total_time_to_green], stats[:count_with_green], 3600.0)

            merge_rate = calculate_rate(stats[:merged], stats[:merged] + stats[:closed])
            unreviewed_pr_rate = calculate_rate(stats[:count_zero_reviews], created_count)
            ci_success_rate = calculate_rate(stats[:count_ci_success], created_count)
            hotfix_rate = calculate_rate(stats[:hotfix_count], stats[:releases_count])

            [
              [date, 'github_daily', 'created', created_count],
              [date, 'github_daily', 'merged', stats[:merged]],
              [date, 'github_daily', 'closed', stats[:closed]],
              [date, 'github_daily', 'open', stats[:open]],
              [date, 'github_daily', 'avg_time_to_merge_hours', avg_merge_time],
              [date, 'github_daily', 'avg_reviews_per_pr', avg_reviews],
              [date, 'github_daily', 'avg_comments_per_pr', avg_comments],
              [date, 'github_daily', 'avg_rework_cycles', avg_rework_cycles],
              [date, 'github_daily', 'avg_additions_per_pr', avg_additions],
              [date, 'github_daily', 'avg_deletions_per_pr', avg_deletions],
              [date, 'github_daily', 'avg_time_to_first_review_days', avg_time_to_first_review],
              [date, 'github_daily', 'avg_time_to_approval_days', avg_time_to_approval],
              [date, 'github_daily', 'avg_time_to_green_hours', avg_time_to_green],
              [date, 'github_daily', 'merge_rate', merge_rate],
              [date, 'github_daily', 'unreviewed_pr_rate', unreviewed_pr_rate],
              [date, 'github_daily', 'ci_success_rate', ci_success_rate],
              [date, 'github_daily', 'hotfix_count', stats[:hotfix_count]],
              [date, 'github_daily', 'hotfix_rate', hotfix_rate],
              [date, 'github_daily', 'releases_count', stats[:releases_count]],
              [date, 'github_daily', 'deploy_frequency_daily', stats[:deploy_frequency_daily]]
            ]
          end
        end

        private

        def calculate_average(total, count, divisor = 1.0)
          return 0.0 unless count.positive?

          (total.to_f / count / divisor).round(2)
        end

        def calculate_rate(numerator, denominator)
          return 0.0 unless denominator.positive?

          ((numerator.to_f / denominator) * 100).round(2)
        end

        def daily_stats
          stats = initialize_stats_hash
          process_pull_requests(stats)
          process_releases(stats)
          stats
        end

        def initialize_stats_hash
          Hash.new do |h, k|
            h[k] = {
              created: 0, merged: 0, closed: 0, open: 0,
              total_merge_time: 0.0, total_reviews: 0, total_comments: 0,
              total_additions: 0, total_deletions: 0,
              total_time_to_first_review: 0.0, count_with_reviews: 0,
              total_rework_cycles: 0, count_zero_reviews: 0, count_ci_success: 0,
              releases_count: 0, total_time_to_approval: 0.0, count_with_approval: 0,
              hotfix_count: 0, total_time_to_green: 0.0, count_with_green: 0
            }
          end
        end

        def process_pull_requests(stats)
          @pull_requests.each do |pull_request|
            date = Date.parse(pull_request[:createdAt]).to_s
            day_stats = stats[date]
            process_pr_metrics(pull_request, day_stats)
          end
        end

        def process_pr_metrics(pull_request, day_stats)
          update_basic_stats(pull_request, day_stats)
          calculate_rework_cycles(pull_request, day_stats)
          calculate_time_to_approval(pull_request, day_stats)
          calculate_unreviewed_prs(pull_request, day_stats)
          calculate_ci_success(pull_request, day_stats)
          calculate_time_to_first_review(pull_request, day_stats)
          update_pr_state_stats(pull_request, day_stats)
        end

        def update_basic_stats(pull_request, day_stats)
          day_stats[:created] += 1
          day_stats[:total_reviews] += pull_request.dig(:reviews, :totalCount) || 0
          day_stats[:total_comments] += pull_request.dig(:comments, :totalCount) || 0
          day_stats[:total_additions] += pull_request[:additions] || 0
          day_stats[:total_deletions] += pull_request[:deletions] || 0
        end

        def calculate_rework_cycles(pull_request, day_stats)
          reviews = pull_request.dig(:reviews, :nodes) || pull_request.dig('reviews', 'nodes')
          rework_cycles = reviews&.count { |r| (r[:state] || r['state']) == 'CHANGES_REQUESTED' } || 0
          day_stats[:total_rework_cycles] += rework_cycles
        end

        def calculate_time_to_approval(pull_request, day_stats)
          reviews = pull_request.dig(:reviews, :nodes) || pull_request.dig('reviews', 'nodes')
          approved_reviews = reviews&.select { |r| (r[:state] || r['state']) == 'APPROVED' }
          return unless approved_reviews&.any?

          first_approval = approved_reviews.min_by { |r| r[:createdAt] || r['createdAt'] }
          created_at = Time.parse(pull_request[:createdAt])
          approval_at = Time.parse(first_approval[:createdAt] || first_approval['createdAt'])

          day_stats[:total_time_to_approval] += (approval_at - created_at)
          day_stats[:count_with_approval] += 1
        end

        def calculate_unreviewed_prs(pull_request, day_stats)
          day_stats[:count_zero_reviews] += 1 if (pull_request.dig(:reviews, :totalCount) || 0).zero?
        end

        def calculate_ci_success(pull_request, day_stats)
          last_commit = pull_request.dig(:lastCommit, :nodes, 0, :commit) ||
                        pull_request.dig('lastCommit', 'nodes', 0, 'commit')
          return unless last_commit

          status = last_commit.dig(:statusCheckRollup, :state) || last_commit.dig('statusCheckRollup', 'state')
          day_stats[:count_ci_success] += 1 if status == 'SUCCESS'
        end

        def calculate_time_to_first_review(pull_request, day_stats)
          reviews = pull_request[:reviews]
          return unless reviews && reviews[:nodes] && !reviews[:nodes].empty?

          first_review = reviews[:nodes].min_by { |r| r[:createdAt] }
          return unless first_review

          created_at = Time.parse(pull_request[:createdAt])
          review_at = Time.parse(first_review[:createdAt])
          day_stats[:total_time_to_first_review] += (review_at - created_at)
          day_stats[:count_with_reviews] += 1
        end

        def update_pr_state_stats(pull_request, day_stats)
          case pull_request[:state]
          when 'MERGED'
            handle_merged_pr(pull_request, day_stats)
          when 'CLOSED'
            day_stats[:closed] += 1
          when 'OPEN'
            day_stats[:open] += 1
          end
        end

        def handle_merged_pr(pull_request, day_stats)
          day_stats[:merged] += 1
          if pull_request[:mergedAt]
            created_at = Time.parse(pull_request[:createdAt])
            merged_at = Time.parse(pull_request[:mergedAt])
            day_stats[:total_merge_time] += (merged_at - created_at)
          end
          calculate_time_to_green(pull_request, day_stats)
        end

        def calculate_time_to_green(pull_request, day_stats)
          last_commit = pull_request.dig(:lastCommit, :nodes, 0, :commit) ||
                        pull_request.dig('lastCommit', 'nodes', 0, 'commit')
          check_suites = last_commit&.dig(:checkSuites, :nodes) || last_commit&.dig('checkSuites', 'nodes')
          return unless check_suites&.any?

          successful_suites = check_suites.select { |cs| (cs[:conclusion] || cs['conclusion']) == 'SUCCESS' }
          return unless successful_suites.any?

          latest_suite = successful_suites.max_by { |cs| cs[:updatedAt] || cs['updatedAt'] }
          return unless latest_suite

          committed_date = last_commit[:committedDate] || last_commit['committedDate']
          return unless committed_date

          committed_at = Time.parse(committed_date)
          suite_updated_at = Time.parse(latest_suite[:updatedAt] || latest_suite['updatedAt'])
          day_stats[:total_time_to_green] += (suite_updated_at - committed_at)
          day_stats[:count_with_green] += 1
        end

        def process_releases(stats)
          @releases.each do |release|
            created_at = release['created_at'] || release[:created_at]
            next unless created_at

            # Handle both Time and String (if serialized)
            date = created_at.is_a?(String) ? Date.parse(created_at).to_s : created_at.to_date.to_s
            stats[date][:releases_count] += 1

            name = release['name'] || ''
            tag = release['tag_name'] || ''
            stats[date][:hotfix_count] += 1 if name.downcase.include?('hotfix') || tag.downcase.include?('hotfix')
          end
        end
      end
    end
  end
end
