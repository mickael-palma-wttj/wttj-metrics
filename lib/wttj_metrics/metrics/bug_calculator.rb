# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Calculates bug-related metrics
    class BugCalculator < Base
      COMPLETED_STATES = %w[completed canceled].freeze
      DAYS_IN_MONTH = 30
      PERCENTAGE_MULTIPLIER = 100

      def calculate
        {
          total: bugs.size,
          open: open_bugs.size,
          closed: closed_bugs.size,
          created_last_30d: bugs_created_last_30_days,
          closed_last_30d: bugs_closed_last_30_days,
          avg_resolution_days: avg_resolution_days,
          bug_ratio: bug_ratio,
          by_priority: bugs_by_priority
        }
      end

      def to_rows
        stats = calculate
        rows = []

        rows << [today_str, 'bugs', 'total_bugs', stats[:total]]
        rows << [today_str, 'bugs', 'open_bugs', stats[:open]]
        rows << [today_str, 'bugs', 'closed_bugs', stats[:closed]]
        rows << [today_str, 'bugs', 'bugs_created_last_30d', stats[:created_last_30d]]
        rows << [today_str, 'bugs', 'bugs_closed_last_30d', stats[:closed_last_30d]]
        rows << [today_str, 'bugs', 'avg_bug_resolution_days', stats[:avg_resolution_days]]
        rows << [today_str, 'bugs', 'bug_ratio', stats[:bug_ratio]]

        stats[:by_priority].each do |priority, count|
          rows << [today_str, 'bugs_by_priority', priority.to_s, count]
        end

        rows
      end

      private

      def bugs
        @bugs ||= issues.select { |issue| issue_is_bug?(issue) }
      end

      def open_bugs
        @open_bugs ||= bugs.reject { |b| COMPLETED_STATES.include?(b.dig('state', 'type')) }
      end

      def closed_bugs
        @closed_bugs ||= bugs.select { |b| COMPLETED_STATES.include?(b.dig('state', 'type')) }
      end

      def today_str
        @today_str ||= today.to_s
      end

      def thirty_days_ago
        @thirty_days_ago ||= today - DAYS_IN_MONTH
      end

      def bugs_created_last_30_days
        bugs.count { |b| parse_date(b['createdAt']) >= thirty_days_ago }
      end

      def bugs_closed_last_30_days
        closed_bugs.count do |b|
          completed = parse_date(b['completedAt'])
          completed && completed >= thirty_days_ago
        end
      end

      def avg_resolution_days
        resolution_times = closed_bugs.filter_map do |b|
          next unless b['completedAt']

          created = parse_date(b['createdAt'])
          completed = parse_date(b['completedAt'])
          (completed - created).to_f
        end

        return 0 if resolution_times.empty?

        (resolution_times.sum / resolution_times.size).round(1)
      end

      def bug_ratio
        return 0 if issues.empty?

        ((bugs.size.to_f / issues.size) * PERCENTAGE_MULTIPLIER).round(1)
      end

      def bugs_by_priority
        open_bugs.each_with_object(Hash.new(0)) do |bug, distribution|
          priority = bug['priorityLabel'] || 'No priority'
          distribution[priority] += 1
        end
      end
    end
  end
end
