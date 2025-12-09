# frozen_string_literal: true

module WttjMetrics
  module Helpers
    module Linear
      # Common helpers for issue data extraction
      module IssueHelper
        def issue_is_bug?(issue)
          labels = extract_labels(issue)
          labels.any? { |l| l.include?('bug') || l.include?('fix') }
        end

        def extract_labels(issue)
          (issue.dig('labels', 'nodes') || []).map { |l| l['name'].downcase }
        end

        def extract_team_name(issue)
          issue.dig('team', 'name') || 'Unknown'
        end

        def extract_assignee_name(issue)
          issue.dig('assignee', 'name') || 'Unassigned'
        end

        def extract_priority_label(issue)
          issue['priorityLabel'] || 'No priority'
        end

        def issue_completed?(issue)
          !issue['completedAt'].nil?
        end

        def issue_started?(issue)
          !issue['startedAt'].nil?
        end
      end
    end
  end
end
