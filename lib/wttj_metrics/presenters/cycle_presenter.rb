# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for cycle (sprint) data in the cycles table
    class CyclePresenter
      include Helpers::FormattingHelper

      def initialize(cycle)
        @cycle = cycle
      end

      def name
        @cycle[:name]
      end

      def status
        @cycle[:status]
      end

      def status_class
        "status-#{status}"
      end

      def progress
        @cycle[:progress] || 0
      end

      def completed_issues
        @cycle[:completed_issues] || 0
      end

      def total_issues
        @cycle[:total_issues] || 0
      end

      def issues_display
        format_count_display(completed_issues, total_issues)
      end

      def bug_count
        @cycle[:bug_count] || 0
      end

      def assignee_count
        @cycle[:assignee_count] || 0
      end

      def velocity
        @cycle[:velocity] || 0
      end

      def velocity_display
        format_points_display(velocity)
      end

      def tickets_per_day
        @cycle[:tickets_per_day] || 0
      end

      def completion_rate
        @cycle[:completion_rate] || 0
      end

      def completion_rate_display
        format_with_unit(completion_rate, '%')
      end

      def carryover
        @cycle[:carryover] || 0
      end

      def scope_change
        @cycle[:scope_change] || 0
      end

      def initial_scope
        @cycle[:initial_scope] || 0
      end

      def final_scope
        @cycle[:final_scope] || 0
      end

      def scope_change_display
        value = scope_change
        sign = value.positive? ? '+' : ''
        "#{sign}#{format_with_unit(value, '%')}"
      end

      def scope_change_tooltip
        "Initial: #{initial_scope} issues → Final: #{final_scope} issues"
      end

      def scope_change_class
        case scope_change
        when -Float::INFINITY...0 then 'scope-decreased'
        when 0 then 'scope-neutral'
        else 'scope-increased'
        end
      end

      def to_h
        {
          name: name,
          status: status,
          status_class: status_class,
          progress: progress,
          completed_issues: completed_issues,
          total_issues: total_issues,
          issues_display: issues_display,
          bug_count: bug_count,
          assignee_count: assignee_count,
          velocity: velocity,
          velocity_display: velocity_display,
          tickets_per_day: tickets_per_day,
          completion_rate: completion_rate,
          completion_rate_display: completion_rate_display,
          carryover: carryover,
          scope_change: scope_change,
          scope_change_display: scope_change_display,
          scope_change_class: scope_change_class
        }
      end
    end
  end
end
