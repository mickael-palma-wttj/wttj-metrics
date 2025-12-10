# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class DailyStats
          def initialize
            @pr_activity = PrActivityMetrics.new
            @reviews = ReviewMetrics.new
            @code = CodeMetrics.new
            @ci = CiMetrics.new
            @releases = ReleaseMetrics.new
          end

          def record_pr(pull_request)
            @pr_activity.record(pull_request)
            @reviews.record(pull_request)
            @code.record(pull_request)
            @ci.record(pull_request)
          end

          def record_release(release)
            @releases.record(release)
          end

          def to_rows(date, category)
            all_metrics.map { |key, value| [date, category, key.to_s, value] }
          end

          private

          def all_metrics
            {
              **@pr_activity.metrics,
              **@reviews.metrics,
              **@code.metrics,
              **@ci.metrics,
              **@releases.metrics,
              merge_rate: merge_rate
            }
          end

          def merge_rate
            merged = @pr_activity.merged
            closed = @pr_activity.closed
            total = merged + closed
            return 0.0 if total.zero?

            ((merged.to_f / total) * 100).round(2)
          end
        end
      end
    end
  end
end
