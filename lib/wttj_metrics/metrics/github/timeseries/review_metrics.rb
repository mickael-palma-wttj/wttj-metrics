# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class ReviewMetrics
          def initialize
            @total_reviews = 0
            @total_comments = 0
            @total_rework_cycles = 0
            @total_time_to_first_review = 0.0
            @count_with_reviews = 0
            @count_zero_reviews = 0
            @total_time_to_approval = 0.0
            @count_with_approval = 0
            @pr_count = 0
          end

          def record(pull_request)
            @pr_count += 1
            update_basic_stats(pull_request)
            update_review_stats(pull_request)
          end

          def metrics
            {
              avg_reviews_per_pr: average(@total_reviews, @pr_count),
              avg_comments_per_pr: average(@total_comments, @pr_count),
              avg_rework_cycles: average(@total_rework_cycles, @pr_count),
              avg_time_to_first_review_days: average(@total_time_to_first_review, @count_with_reviews, 86_400.0),
              avg_time_to_approval_days: average(@total_time_to_approval, @count_with_approval, 86_400.0),
              unreviewed_pr_rate: rate(@count_zero_reviews, @pr_count)
            }
          end

          private

          def update_basic_stats(pull_request)
            @total_reviews += fetch(pull_request, :reviews, :totalCount) || 0
            @total_comments += fetch(pull_request, :comments, :totalCount) || 0
          end

          def update_review_stats(pull_request)
            reviews = fetch(pull_request, :reviews, :nodes)
            return unless reviews

            calculate_rework_cycles(reviews)
            calculate_time_to_approval(pull_request, reviews)
            calculate_time_to_first_review(pull_request, reviews)
            @count_zero_reviews += 1 if reviews.empty?
          end

          def calculate_rework_cycles(reviews)
            count = reviews.count { |r| (r[:state] || r['state']) == 'CHANGES_REQUESTED' }
            @total_rework_cycles += count
          end

          def calculate_time_to_approval(pull_request, reviews)
            approved = reviews.select { |r| (r[:state] || r['state']) == 'APPROVED' }
            return if approved.empty?

            first = approved.min_by { |r| r[:createdAt] || r['createdAt'] }
            pr_created_at = Time.parse(pull_request[:createdAt] || pull_request['createdAt'])
            first_approved_at = Time.parse(first[:createdAt] || first['createdAt'])
            duration = first_approved_at - pr_created_at
            @total_time_to_approval += duration
            @count_with_approval += 1
          end

          def calculate_time_to_first_review(pull_request, reviews)
            return if reviews.empty?

            first = reviews.min_by { |r| r[:createdAt] || r['createdAt'] }
            pr_created_at = Time.parse(pull_request[:createdAt] || pull_request['createdAt'])
            first_review_at = Time.parse(first[:createdAt] || first['createdAt'])
            duration = first_review_at - pr_created_at
            @total_time_to_first_review += duration
            @count_with_reviews += 1
          end

          def fetch(obj, *keys)
            keys.reduce(obj) do |memo, key|
              memo.is_a?(Hash) ? (memo[key] || memo[key.to_s]) : nil
            end
          end

          def average(total, count, divisor = 1.0)
            return 0.0 unless count&.positive?

            (total.to_f / count / divisor).round(2)
          end

          def rate(numerator, denominator)
            return 0.0 unless denominator&.positive?

            ((numerator.to_f / denominator) * 100).round(2)
          end
        end
      end
    end
  end
end
