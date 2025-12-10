# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      # Calculates flow metrics: cycle time, lead time, throughput, WIP
      class FlowCalculator < Base
        DAYS_IN_WEEK = 7
        REVIEW_STATE_PATTERN = /review|validate|test|merge/i
        AVERAGE_PRECISION = 2
        STARTED_STATE = 'started'
        COMPLETED_STATE = 'completed'

        def calculate
          {
            avg_cycle_time_days: avg_cycle_time,
            avg_lead_time_days: avg_lead_time,
            avg_review_time_days: avg_review_time,
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
          average_duration(cycle_time_eligible_issues) do |issue|
            duration_between(issue['startedAt'], issue['completedAt'])
          end
        end

        def cycle_time_eligible_issues
          issues.select { |issue| cycle_time_data?(issue) }
        end

        def cycle_time_data?(issue)
          issue['completedAt'] && issue['startedAt']
        end

        def avg_lead_time
          average_duration(completed_issues) do |issue|
            duration_between(issue['createdAt'], issue['completedAt'])
          end
        end

        def weekly_throughput
          issues.count { |issue| completed_in_last_week?(issue) }
        end

        def completed_in_last_week?(issue)
          return false unless issue['completedAt']

          parse_datetime(issue['completedAt']) >= one_week_ago
        end

        def one_week_ago
          @one_week_ago ||= (today - DAYS_IN_WEEK).to_datetime
        end

        def current_wip
          filter_issues_by_state(STARTED_STATE).count
        end

        def filter_issues_by_state(state_type)
          issues.select { |issue| issue.dig('state', 'type') == state_type }
        end

        def completed_issues
          @completed_issues ||= filter_issues_by_state(COMPLETED_STATE)
        end

        def avg_review_time
          average_from_collection(collect_review_times)
        end

        def collect_review_times
          issues.flat_map { |issue| calculate_review_times(issue) }
        end

        def calculate_review_times(issue)
          calculate_state_durations(issue, :entering_review?, :leaving_review?)
        end

        def calculate_state_durations(issue, enter_predicate, leave_predicate)
          history = sorted_history(issue)
          durations = []
          state_entry_time = nil

          history.each do |event|
            if send(enter_predicate, event)
              state_entry_time = parse_datetime(event['createdAt'])
            elsif state_entry_time && send(leave_predicate, event)
              durations << duration_in_days(state_entry_time, event['createdAt'])
              state_entry_time = nil
            end
          end

          durations
        end

        def entering_review?(event)
          state_matches_pattern?(event.dig('toState', 'name'), REVIEW_STATE_PATTERN)
        end

        def leaving_review?(event)
          state_matches_pattern?(event.dig('fromState', 'name'), REVIEW_STATE_PATTERN)
        end

        def state_matches_pattern?(state_name, pattern)
          return false unless state_name

          state_name.match?(pattern)
        end

        def sorted_history(issue)
          (issue.dig('history', 'nodes') || []).sort_by { |h| h['createdAt'] }
        end

        def average_duration(collection, &)
          return 0 if collection.empty?

          total = collection.sum(&)
          round_to_precision(total / collection.size)
        end

        def average_from_collection(values)
          return 0 if values.empty?

          round_to_precision(values.sum / values.size)
        end

        def round_to_precision(value)
          value.round(AVERAGE_PRECISION)
        end

        def duration_between(start_field, end_field)
          calculate_duration(parse_datetime(start_field), parse_datetime(end_field))
        end

        def duration_in_days(start_time, end_field)
          calculate_duration(start_time, parse_datetime(end_field))
        end

        def calculate_duration(start_time, end_time)
          (end_time - start_time).to_f
        end
      end
    end
  end
end
