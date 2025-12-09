# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
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
          distribution = {
            'Feature' => 0,
            'Bug' => 0,
            'Improvement' => 0,
            'Tech Debt' => 0,
            'Task' => 0,
            'Documentation' => 0,
            'Other' => 0
          }

          issues.each do |issue|
            distribution[classify_issue_type(issue)] += 1
          end

          distribution
        end

        def classify_issue_type(issue)
          labels = extract_labels(issue)
          title = (issue['title'] || '').downcase

          # Priority order matters - check most specific first
          # Try label-based classification first (more reliable)
          return 'Bug' if bug_pattern?(labels)
          return 'Feature' if feature_pattern?(labels)
          return 'Improvement' if improvement_pattern?(labels)
          return 'Tech Debt' if tech_debt_pattern?(labels)
          return 'Task' if task_pattern?(labels)
          return 'Documentation' if documentation_pattern?(labels)

          # Fallback to title-based patterns for unlabeled issues
          return 'Bug' if title_indicates_bug?(title)
          return 'Feature' if title_indicates_feature?(title)
          return 'Improvement' if title_indicates_improvement?(title)
          return 'Tech Debt' if title_indicates_tech_debt?(title)
          return 'Task' if title_indicates_task?(title)
          return 'Documentation' if title_indicates_documentation?(title)

          'Other'
        end

        def bug_pattern?(labels)
          labels.any? { |l| l =~ /\b(bug|bugs|hotfix|fix)\b/ }
        end

        def feature_pattern?(labels)
          labels.any? { |l| l =~ /\b(feature|enhancement|ai-feature)\b/ }
        end

        def improvement_pattern?(labels)
          labels.any? { |l| l =~ /\bimprovement/ }
        end

        def tech_debt_pattern?(labels)
          labels.any? do |l|
            l =~ /\b(debt|refactor|migration|migrated|upgrade|component upgrade)\b/ &&
              !l.include?('front-end') &&
              !l.include?('back-end') &&
              l != 'tech'
          end
        end

        def task_pattern?(labels)
          labels.any? { |l| l =~ /\b(task|chore|cooldown|testing|manual testing)\b/ }
        end

        def documentation_pattern?(labels)
          labels.any? { |l| l =~ /\b(doc|documentation|writing|content fix)\b/ }
        end

        # Title-based classification methods (fallback for unlabeled issues)
        def title_indicates_bug?(title)
          title =~ /\[bug\]|^bug[:\s]|fix\s+(bug|issue|error)|broken|crash|not working/i
        end

        def title_indicates_feature?(title)
          # Avoid matching simple "add" for config/docs; look for "add new X" or "create X"
          title =~ /\badd\s+(new|support|ability|feature|functionality)|^create\s+\w+\s+(for|to)|
                     implement\s+new|introduce\s+/xi
        end

        def title_indicates_improvement?(title)
          title =~ /\bimprove|enhance|optimize|better|refine|polish|cleanup/i
        end

        def title_indicates_tech_debt?(title)
          title =~ /\brefactor|upgrade|migrate|migration|update\s+\w+\s+to\s+|modernize|consolidate/i
        end

        def title_indicates_task?(title)
          # Generic task indicators or exploratory work
          title =~ /^(explore|investigate|research|review|analyze|test|verify|validate|check)\b/i
        end

        def title_indicates_documentation?(title)
          title =~ /\bdocument|docs|readme|guide|tutorial|example|write\s+doc/i
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
end
