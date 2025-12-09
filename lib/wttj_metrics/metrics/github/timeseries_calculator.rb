# frozen_string_literal: true

require 'date'
require 'time'

module WttjMetrics
  module Metrics
    module Github
      class TimeseriesCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def to_rows
          daily_stats.flat_map do |date, stats|
            avg_merge_time = calculate_average(stats[:total_merge_time], stats[:merged], 3600.0)
            avg_reviews = calculate_average(stats[:total_reviews], stats[:created])
            avg_comments = calculate_average(stats[:total_comments], stats[:created])
            avg_additions = calculate_average(stats[:total_additions], stats[:created])
            avg_deletions = calculate_average(stats[:total_deletions], stats[:created])
            avg_time_to_first_review = calculate_average(
              stats[:total_time_to_first_review],
              stats[:count_with_reviews],
              3600.0
            )

            [
              [date, 'github_daily', 'created', stats[:created]],
              [date, 'github_daily', 'merged', stats[:merged]],
              [date, 'github_daily', 'closed', stats[:closed]],
              [date, 'github_daily', 'open', stats[:open]],
              [date, 'github_daily', 'avg_time_to_merge_hours', avg_merge_time],
              [date, 'github_daily', 'avg_reviews_per_pr', avg_reviews],
              [date, 'github_daily', 'avg_comments_per_pr', avg_comments],
              [date, 'github_daily', 'avg_additions_per_pr', avg_additions],
              [date, 'github_daily', 'avg_deletions_per_pr', avg_deletions],
              [date, 'github_daily', 'avg_time_to_first_review_hours', avg_time_to_first_review]
            ]
          end
        end

        private

        def calculate_average(total, count, divisor = 1.0)
          return 0.0 unless count.positive?

          (total.to_f / count / divisor).round(2)
        end

        def daily_stats
          stats = Hash.new do |h, k|
            h[k] = {
              created: 0, merged: 0, closed: 0, open: 0,
              total_merge_time: 0.0, total_reviews: 0, total_comments: 0,
              total_additions: 0, total_deletions: 0,
              total_time_to_first_review: 0.0, count_with_reviews: 0
            }
          end

          @pull_requests.each do |pr|
            date = Date.parse(pr[:createdAt]).to_s
            day_stats = stats[date]

            day_stats[:created] += 1
            day_stats[:total_reviews] += pr.dig(:reviews, :totalCount) || 0
            day_stats[:total_comments] += pr.dig(:comments, :totalCount) || 0
            day_stats[:total_additions] += pr[:additions] || 0
            day_stats[:total_deletions] += pr[:deletions] || 0

            if pr[:reviews] && pr[:reviews][:nodes] && !pr[:reviews][:nodes].empty?
              first_review = pr[:reviews][:nodes].min_by { |r| r[:createdAt] }
              if first_review
                created_at = Time.parse(pr[:createdAt])
                review_at = Time.parse(first_review[:createdAt])
                day_stats[:total_time_to_first_review] += (review_at - created_at)
                day_stats[:count_with_reviews] += 1
              end
            end

            case pr[:state]
            when 'MERGED'
              day_stats[:merged] += 1
              if pr[:mergedAt]
                created_at = Time.parse(pr[:createdAt])
                merged_at = Time.parse(pr[:mergedAt])
                day_stats[:total_merge_time] += (merged_at - created_at)
              end
            when 'CLOSED'
              day_stats[:closed] += 1
            when 'OPEN'
              day_stats[:open] += 1
            end
          end

          stats
        end
      end
    end
  end
end
