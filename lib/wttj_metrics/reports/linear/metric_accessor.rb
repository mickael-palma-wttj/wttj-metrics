# frozen_string_literal: true

module WttjMetrics
  module Reports
    module Linear
      # Provides cached access to parsed metrics
      # Single Responsibility: Metric data access with memoization
      class MetricAccessor
        def initialize(parser)
          @parser = parser
        end

        def flow_metrics
          @flow_metrics ||= @parser.metrics_for('flow')
        end

        def cycle_metrics
          @cycle_metrics ||= @parser.metrics_for('cycle_metrics')
        end

        def team_metrics
          @team_metrics ||= @parser.metrics_for('team')
        end

        def bug_metrics
          @bug_metrics ||= @parser.metrics_for('bugs')
        end

        def bugs_by_priority
          @bugs_by_priority ||= @parser.metrics_for('bugs_by_priority')
        end

        def status_dist
          @status_dist ||= @parser.metrics_for('status')
        end

        def priority_dist
          @priority_dist ||= @parser.metrics_for('priority')
        end

        def type_dist
          @type_dist ||= @parser.metrics_for('type')
        end

        def assignee_dist
          @assignee_dist ||= @parser.metrics_for('assignee')
                                    .sort_by { |m| -m[:value] }
                                    .first(15)
        end
      end
    end
  end
end
