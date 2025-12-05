# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Calculates flow metrics: cycle time, lead time, throughput, WIP
    class FlowCalculator < Base
      def calculate
        {
          avg_cycle_time_days: avg_cycle_time,
          avg_lead_time_days: avg_lead_time,
          weekly_throughput: weekly_throughput,
          current_wip: current_wip
        }
      end

      def to_rows
        calculate.map do |metric, value|
          [today.to_s, 'flow', metric.to_s, value]
        end
      end

      private

      def avg_cycle_time
        started_and_completed = issues.select { |i| i['completedAt'] && i['startedAt'] }
        return 0 if started_and_completed.empty?

        total_days = started_and_completed.sum do |issue|
          started = parse_datetime(issue['startedAt'])
          completed_at = parse_datetime(issue['completedAt'])
          (completed_at - started).to_f
        end

        (total_days / started_and_completed.size).round(2)
      end

      def avg_lead_time
        return 0 if completed_issues.empty?

        total_days = completed_issues.sum do |issue|
          created = parse_datetime(issue['createdAt'])
          completed_at = parse_datetime(issue['completedAt'])
          (completed_at - created).to_f
        end

        (total_days / completed_issues.size).round(2)
      end

      def weekly_throughput
        week_ago = (today - 7).to_datetime

        issues.count do |issue|
          next false unless issue['completedAt']

          parse_datetime(issue['completedAt']) >= week_ago
        end
      end

      def current_wip
        issues.count { |issue| issue.dig('state', 'type') == 'started' }
      end
    end
  end
end
