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
            avg_additions: median_metric { |pr| pr[:additions] },
            avg_deletions: median_metric { |pr| pr[:deletions] },
            avg_changed_files: median_metric { |pr| pr[:changedFiles] },
            avg_commits: median_metric { |pr| pr.dig(:commits, :totalCount) }
          }
        end

        def to_rows(category = CATEGORY)
          return [] if @pull_requests.empty?

          date = Date.today.to_s
          calculate.map do |metric_key, value|
            [date, category, METRICS[metric_key], value]
          end
        end

        private

        def median_metric
          values = @pull_requests.map { |pr| yield(pr) || 0 }.map(&:to_f)
          median(values).round(2)
        end

        def median(values)
          return 0.0 if values.empty?

          sorted = values.sort
          mid = sorted.length / 2
          return sorted[mid] if sorted.length.odd?

          (sorted[mid - 1] + sorted[mid]) / 2.0
        end
      end
    end
  end
end
