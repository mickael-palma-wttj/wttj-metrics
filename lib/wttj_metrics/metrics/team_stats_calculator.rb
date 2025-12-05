# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Calculates aggregate statistics for team cycles
    # Single Responsibility: Team statistics calculation
    class TeamStatsCalculator
      COUNTABLE_STATUSES = %w[completed active].freeze

      def initialize(cycles_by_team)
        @cycles_by_team = cycles_by_team
      end

      def calculate
        @cycles_by_team.transform_values { |cycles| calculate_team_stats(cycles) }
      end

      private

      def calculate_team_stats(cycles)
        active_cycles = select_active_cycles(cycles)

        {
          total_cycles: cycles.size,
          cycles_with_data: active_cycles.size,
          avg_velocity: average(active_cycles, :velocity),
          avg_tickets_per_cycle: average(active_cycles, :completed_issues),
          avg_assignees: average(active_cycles, :assignee_count),
          avg_completion_rate: average(active_cycles, :completion_rate),
          avg_tickets_per_day: average(active_cycles, :tickets_per_day, precision: 2),
          total_carryover: sum(active_cycles, :carryover)
        }
      end

      def select_active_cycles(cycles)
        cycles.select do |c|
          COUNTABLE_STATUSES.include?(c[:status]) && (c[:total_issues] || 0).positive?
        end
      end

      def average(cycles, field, precision: 1)
        return 0 if cycles.empty?

        total = cycles.sum { |c| c[field] || 0 }
        (total.to_f / cycles.size).round(precision)
      end

      def sum(cycles, field)
        cycles.sum { |c| c[field] || 0 }
      end
    end
  end
end
