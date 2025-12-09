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
            avg_comments_per_pr: (total_comments.to_f / count).round(2)
          }
        end

        def to_rows
          stats = calculate
          return [] if stats.empty?

          date = Date.today.to_s
          [
            [date, 'github', 'avg_reviews_per_pr', stats[:avg_reviews_per_pr]],
            [date, 'github', 'avg_comments_per_pr', stats[:avg_comments_per_pr]]
          ]
        end
      end
    end
  end
end
