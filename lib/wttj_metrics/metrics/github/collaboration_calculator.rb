# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class CollaborationCalculator
        CATEGORY = 'github'

        attr_reader :pull_requests

        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          return {} if pull_requests.empty?

          {
            avg_reviews_per_pr: avg_reviews_per_pr,
            avg_comments_per_pr: avg_comments_per_pr,
            avg_rework_cycles: avg_rework_cycles,
            unreviewed_pr_rate: unreviewed_pr_rate
          }
        end

        def to_rows(category = CATEGORY)
          calculate.map do |metric, value|
            [Date.today.to_s, category, metric.to_s, value]
          end
        end

        private

        def count
          @count ||= pull_requests.size
        end

        def avg_reviews_per_pr
          calculate_average { |pr| pr.dig(:reviews, :totalCount) || 0 }
        end

        def avg_comments_per_pr
          calculate_average { |pr| pr.dig(:comments, :totalCount) || 0 }
        end

        def avg_rework_cycles
          total = pull_requests.sum { |pr| count_changes_requested(pr) }
          (total.to_f / count).round(2)
        end

        def unreviewed_pr_rate
          unreviewed = pull_requests.count { |pr| (pr.dig(:reviews, :totalCount) || 0).zero? }
          (unreviewed.to_f / count * 100).round(2)
        end

        def calculate_average(&)
          total = pull_requests.sum(&)
          (total.to_f / count).round(2)
        end

        def count_changes_requested(pull_request)
          reviews = pull_request.dig(:reviews, :nodes) || []
          reviews.count { |review| review[:state] == 'CHANGES_REQUESTED' }
        end
      end
    end
  end
end
