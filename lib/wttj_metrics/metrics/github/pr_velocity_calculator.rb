# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class PrVelocityCalculator
        CATEGORY = 'github'
        METRICS = {
          avg_time_to_merge_days: 'avg_time_to_merge_days',
          total_merged: 'total_merged_prs',
          avg_time_to_first_review_days: 'avg_time_to_first_review_days',
          merge_rate: 'merge_rate',
          avg_time_to_approval_days: 'avg_time_to_approval_days'
        }.freeze

        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          return {} if @pull_requests.empty?

          {
            avg_time_to_merge_days: avg_time_to_merge,
            total_merged: merged_prs.size,
            avg_time_to_first_review_days: avg_time_to_first_review,
            merge_rate: merge_rate,
            avg_time_to_approval_days: avg_time_to_approval
          }
        end

        def to_rows
          return [] if @pull_requests.empty?

          date = Date.today.to_s
          calculate.map do |key, value|
            [date, CATEGORY, METRICS[key], value]
          end
        end

        private

        def merged_prs
          @merged_prs ||= @pull_requests.select { |pr| pr[:state] == 'MERGED' }
        end

        def avg_time_to_merge
          return 0.0 if merged_prs.empty?

          average_duration(merged_prs) do |pr|
            days_between(pr[:createdAt], pr[:mergedAt])
          end
        end

        def avg_time_to_first_review
          prs_with_reviews = @pull_requests.select { |pr| reviews(pr).any? }
          return 0.0 if prs_with_reviews.empty?

          average_duration(prs_with_reviews) do |pr|
            first_review = reviews(pr).min_by { |r| r[:createdAt] }
            days_between(pr[:createdAt], first_review[:createdAt])
          end
        end

        def merge_rate
          closed_count = @pull_requests.count { |pr| pr[:state] == 'CLOSED' }
          total = merged_prs.size + closed_count
          return 0.0 if total.zero?

          (merged_prs.size.to_f / total * 100).round(2)
        end

        def avg_time_to_approval
          prs_with_approval = @pull_requests.select { |pr| approvals(pr).any? }
          return 0.0 if prs_with_approval.empty?

          average_duration(prs_with_approval) do |pr|
            first_approval = approvals(pr).min_by { |r| r[:createdAt] }
            days_between(pr[:createdAt], first_approval[:createdAt])
          end
        end

        def reviews(pull_request)
          pull_request.dig(:reviews, :nodes) || []
        end

        def approvals(pull_request)
          reviews(pull_request).select { |r| r[:state] == 'APPROVED' }
        end

        def days_between(start_date, end_date)
          (DateTime.parse(end_date) - DateTime.parse(start_date)).to_f
        end

        def average_duration(collection, &)
          total = collection.sum(&)
          (total / collection.size).round(4)
        end
      end
    end
  end
end
