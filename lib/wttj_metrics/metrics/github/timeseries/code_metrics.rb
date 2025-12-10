# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class CodeMetrics
          def initialize
            @total_additions = 0
            @total_deletions = 0
            @pr_count = 0
          end

          def record(pull_request)
            @pr_count += 1
            @total_additions += pull_request[:additions] || pull_request['additions'] || 0
            @total_deletions += pull_request[:deletions] || pull_request['deletions'] || 0
          end

          def metrics
            {
              avg_additions_per_pr: average(@total_additions),
              avg_deletions_per_pr: average(@total_deletions)
            }
          end

          private

          def average(total)
            return 0.0 if @pr_count.zero?

            (total.to_f / @pr_count).round(2)
          end
        end
      end
    end
  end
end
