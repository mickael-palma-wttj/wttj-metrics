# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class PrSizeCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          return {} if @pull_requests.empty?

          total_additions = @pull_requests.sum { |pr| pr[:additions] || 0 }
          total_deletions = @pull_requests.sum { |pr| pr[:deletions] || 0 }
          total_files = @pull_requests.sum { |pr| pr[:changedFiles] || 0 }
          total_commits = @pull_requests.sum { |pr| pr.dig(:commits, :totalCount) || 0 }
          count = @pull_requests.size

          {
            avg_additions: (total_additions.to_f / count).round(2),
            avg_deletions: (total_deletions.to_f / count).round(2),
            avg_changed_files: (total_files.to_f / count).round(2),
            avg_commits: (total_commits.to_f / count).round(2)
          }
        end

        def to_rows
          stats = calculate
          return [] if stats.empty?

          date = Date.today.to_s
          [
            [date, 'github', 'avg_additions_per_pr', stats[:avg_additions]],
            [date, 'github', 'avg_deletions_per_pr', stats[:avg_deletions]],
            [date, 'github', 'avg_changed_files_per_pr', stats[:avg_changed_files]],
            [date, 'github', 'avg_commits_per_pr', stats[:avg_commits]]
          ]
        end
      end
    end
  end
end
