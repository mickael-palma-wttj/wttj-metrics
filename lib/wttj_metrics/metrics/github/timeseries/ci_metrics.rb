# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class CiMetrics
          def initialize
            @count_ci_success = 0
            @total_time_to_green = 0.0
            @count_with_green = 0
            @pr_count = 0
          end

          def record(pull_request)
            @pr_count += 1
            update_ci_success(pull_request)
            update_time_to_green(pull_request)
          end

          def metrics
            {
              ci_success_rate: rate(@count_ci_success, @pr_count),
              avg_time_to_green_hours: average(@total_time_to_green, @count_with_green, 3600.0)
            }
          end

          private

          def update_ci_success(pull_request)
            last_commit = fetch_last_commit(pull_request)
            return unless last_commit

            status = last_commit.dig(:statusCheckRollup, :state) || last_commit.dig('statusCheckRollup', 'state')
            @count_ci_success += 1 if status == 'SUCCESS'
          end

          def update_time_to_green(pull_request)
            return unless (pull_request[:state] || pull_request['state']) == 'MERGED'

            last_commit = fetch_last_commit(pull_request)
            return unless last_commit

            suites = last_commit.dig(:checkSuites, :nodes) || last_commit.dig('checkSuites', 'nodes')
            return unless suites

            success_suite = suites.select { |cs| (cs[:conclusion] || cs['conclusion']) == 'SUCCESS' }
                                  .max_by { |cs| cs[:updatedAt] || cs['updatedAt'] }
            return unless success_suite

            committed_at = Time.parse(last_commit[:committedDate] || last_commit['committedDate'])
            suite_at = Time.parse(success_suite[:updatedAt] || success_suite['updatedAt'])
            @total_time_to_green += (suite_at - committed_at)
            @count_with_green += 1
          end

          def fetch_last_commit(pull_request)
            pull_request.dig(:lastCommit, :nodes)&.first&.dig(:commit) ||
              pull_request.dig('lastCommit', 'nodes')&.first&.dig('commit')
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
