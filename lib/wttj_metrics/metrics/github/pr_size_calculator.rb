# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class PrSizeCalculator
        CATEGORY = 'github'
        METRICS = {
          avg_additions: 'avg_additions_per_pr',
          avg_deletions: 'avg_deletions_per_pr',
          avg_changed_files: 'avg_changed_files_per_pr',
          avg_commits: 'avg_commits_per_pr'
        }.freeze

        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          return {} if @pull_requests.empty?

          {
            avg_additions: average_metric { |pr| pr[:additions] },
            avg_deletions: average_metric { |pr| pr[:deletions] },
            avg_changed_files: average_metric { |pr| pr[:changedFiles] },
            avg_commits: average_metric { |pr| pr.dig(:commits, :totalCount) }
          }
        end

        def to_rows
          return [] if @pull_requests.empty?

          date = Date.today.to_s
          calculate.map do |metric_key, value|
            [date, CATEGORY, METRICS[metric_key], value]
          end
        end

        private

        def average_metric
          total = @pull_requests.sum { |pr| yield(pr) || 0 }
          (total.to_f / @pull_requests.size).round(2)
        end
      end
    end
  end
end
