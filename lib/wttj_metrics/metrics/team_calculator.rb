# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Calculates team performance metrics
    class TeamCalculator < Base
      def calculate
        {
          completion_rate: completion_rate,
          avg_blocked_time_hours: avg_blocked_time
        }
      end

      def to_rows
        calculate.map do |metric, value|
          [today.to_s, 'team', metric.to_s, value]
        end
      end

      private

      def completion_rate
        recent = recent_issues
        return 0 if recent.empty?

        completed = recent.count { |i| i['completedAt'] }
        ((completed.to_f / recent.size) * 100).round(2)
      end

      def recent_issues
        thirty_days_ago = (today - 30).to_datetime

        issues.select do |issue|
          created = parse_datetime(issue['createdAt'])
          created >= thirty_days_ago
        end
      end

      def avg_blocked_time
        blocked_times = collect_blocked_times
        return 0 if blocked_times.empty?

        (blocked_times.sum / blocked_times.size).round(2)
      end

      def collect_blocked_times
        issues.flat_map { |issue| calculate_blocked_times(issue) }
      end

      def calculate_blocked_times(issue)
        history = issue.dig('history', 'nodes') || []
        times = []
        blocked_start = nil

        history.sort_by { |h| h['createdAt'] }.each do |event|
          if entering_blocked?(event)
            blocked_start = parse_datetime(event['createdAt'])
          elsif blocked_start && leaving_blocked?(event)
            blocked_end = parse_datetime(event['createdAt'])
            times << ((blocked_end - blocked_start) * 24)
            blocked_start = nil
          end
        end

        times
      end

      def entering_blocked?(event)
        event.dig('toState', 'name')&.downcase&.include?('blocked')
      end

      def leaving_blocked?(event)
        event.dig('fromState', 'name')&.downcase&.include?('blocked')
      end
    end
  end
end
