# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class PrVelocityCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          merged_prs = @pull_requests.select { |pr| pr[:state] == 'MERGED' }
          return {} if merged_prs.empty?

          total_time = merged_prs.sum do |pr|
            (DateTime.parse(pr[:mergedAt]) - DateTime.parse(pr[:createdAt])).to_f
          end

          avg_days = total_time / merged_prs.size

          # Time to first review
          prs_with_reviews = @pull_requests.select do |pr|
            pr[:reviews] && pr[:reviews][:nodes] && !pr[:reviews][:nodes].empty?
          end
          avg_review_time = 0
          if prs_with_reviews.any?
            total_review_time = prs_with_reviews.sum do |pr|
              first_review = pr[:reviews][:nodes].min_by { |r| r[:createdAt] }
              (DateTime.parse(first_review[:createdAt]) - DateTime.parse(pr[:createdAt])).to_f
            end
            avg_review_time = (total_review_time / prs_with_reviews.size).round(4)
          end

          {
            avg_time_to_merge_days: avg_days.round(4),
            total_merged: merged_prs.size,
            avg_time_to_first_review_days: avg_review_time
          }
        end

        def to_rows
          stats = calculate
          return [] if stats.empty?

          date = Date.today.to_s
          [
            [date, 'github', 'avg_time_to_merge_days', stats[:avg_time_to_merge_days]],
            [date, 'github', 'total_merged_prs', stats[:total_merged]],
            [date, 'github', 'avg_time_to_first_review_days', stats[:avg_time_to_first_review_days]]
          ]
        end
      end
    end
  end
end
