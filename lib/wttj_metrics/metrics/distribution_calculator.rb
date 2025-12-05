# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Calculates distribution metrics (status, priority, type, size, assignee)
    class DistributionCalculator < Base
      def calculate
        {
          status: status_distribution,
          priority: priority_distribution,
          type: type_distribution,
          size: size_distribution,
          assignee: assignee_distribution
        }
      end

      def to_rows
        rows = []

        calculate.each do |category, distribution|
          distribution.each do |key, value|
            rows << [today.to_s, category.to_s, key.to_s, value]
          end
        end

        rows
      end

      # Also expose backlog age as an issue characteristic
      def backlog_metrics
        { avg_backlog_age_days: avg_backlog_age }
      end

      def backlog_rows
        [[today.to_s, 'issues', 'avg_backlog_age_days', avg_backlog_age]]
      end

      private

      def status_distribution
        issues.each_with_object(Hash.new(0)) do |issue, dist|
          state = issue.dig('state', 'name') || 'Unknown'
          dist[state] += 1
        end
      end

      def priority_distribution
        issues.each_with_object(Hash.new(0)) do |issue, dist|
          priority = issue['priorityLabel'] || 'No priority'
          dist[priority] += 1
        end
      end

      def type_distribution
        distribution = { 'Feature' => 0, 'Bug' => 0, 'Tech Debt' => 0, 'Other' => 0 }

        issues.each do |issue|
          distribution[classify_issue_type(issue)] += 1
        end

        distribution
      end

      def classify_issue_type(issue)
        labels = extract_labels(issue)

        return 'Bug' if labels.any? { |l| l.include?('bug') || l.include?('fix') }
        return 'Tech Debt' if labels.any? { |l| l.include?('tech') || l.include?('debt') || l.include?('refactor') }
        return 'Feature' if labels.any? { |l| l.include?('feature') || l.include?('enhancement') }

        'Other'
      end

      def extract_labels(issue)
        (issue.dig('labels', 'nodes') || []).map { |l| l['name'].downcase }
      end

      def size_distribution
        distribution = { 'No estimate' => 0, 'Small (1-2)' => 0, 'Medium (3-5)' => 0, 'Large (8+)' => 0 }

        issues.each do |issue|
          distribution[classify_size(issue['estimate'])] += 1
        end

        distribution
      end

      def classify_size(estimate)
        case estimate
        when nil, 0 then 'No estimate'
        when 1, 2 then 'Small (1-2)'
        when 3, 4, 5 then 'Medium (3-5)'
        else 'Large (8+)'
        end
      end

      def assignee_distribution
        in_progress_issues.each_with_object(Hash.new(0)) do |issue, dist|
          assignee = issue.dig('assignee', 'name') || 'Unassigned'
          dist[assignee] += 1
        end
      end

      def in_progress_issues
        issues.select { |i| i.dig('state', 'type') == 'started' }
      end

      def avg_backlog_age
        backlog = issues.select { |i| i.dig('state', 'type') == 'backlog' }
        return 0 if backlog.empty?

        total_days = backlog.sum do |issue|
          created = parse_datetime(issue['createdAt'])
          (today.to_datetime - created).to_f
        end

        (total_days / backlog.size).round(2)
      end
    end
  end
end
