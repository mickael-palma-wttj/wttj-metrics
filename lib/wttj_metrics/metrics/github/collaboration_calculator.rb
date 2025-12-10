# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class CollaborationCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          return {} if @pull_requests.empty?

          total_reviews = @pull_requests.sum { |pr| pr[:reviews][:totalCount] }
          total_comments = @pull_requests.sum { |pr| pr[:comments][:totalCount] }
          count = @pull_requests.size

          {
            avg_reviews_per_pr: (total_reviews.to_f / count).round(2),
            avg_comments_per_pr: (total_comments.to_f / count).round(2),
            avg_rework_cycles: calculate_rework_cycles(count),
            unreviewed_pr_rate: calculate_unreviewed_rate(count)
          }
        end

        def to_rows
          stats = calculate
          return [] if stats.empty?

          date = Date.today.to_s
          [
            [date, 'github', 'avg_reviews_per_pr', stats[:avg_reviews_per_pr]],
            [date, 'github', 'avg_comments_per_pr', stats[:avg_comments_per_pr]],
            [date, 'github', 'avg_rework_cycles', stats[:avg_rework_cycles]],
            [date, 'github', 'unreviewed_pr_rate', stats[:unreviewed_pr_rate]]
          ]
        end

        private

        def calculate_rework_cycles(count)
          total_changes_requested = @pull_requests.sum do |pr|
            # Handle both symbol and string keys
            reviews = pr.dig(:reviews, :nodes) || pr.dig('reviews', 'nodes')

            changes_requested_count = reviews&.count { |r| (r[:state] || r['state']) == 'CHANGES_REQUESTED' } || 0
            changes_requested_count
          end
          (total_changes_requested.to_f / count).round(2)
        end

        def calculate_unreviewed_rate(count)
          unreviewed = @pull_requests.count { |pr| pr[:reviews][:totalCount].zero? }
          (unreviewed.to_f / count * 100).round(2)
        end
      end
    end
  end
end
