# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Linear
      # Parses cycle metrics and organizes them by team
      # Single Responsibility: Cycle data parsing and organization
      class CycleParser
        DEFAULT_TEAMS = Reports::ReportGenerator::SELECTED_TEAMS

        METRIC_PARSERS = {
          'total_issues' => lambda(&:to_i),
          'completed_issues' => lambda(&:to_i),
          'bug_count' => lambda(&:to_i),
          'velocity' => lambda(&:to_i),
          'planned_points' => lambda(&:to_i),
          'completion_rate' => ->(v) { v.to_f.round },
          'carryover' => lambda(&:to_i),
          'progress' => ->(v) { v.to_f.round },
          'duration_days' => lambda(&:to_i),
          'tickets_per_day' => ->(v) { v.to_f.round },
          'assignee_count' => lambda(&:to_i),
          'status' => ->(v) { v.to_s.strip },
          'scope_change' => ->(v) { v.to_f.round },
          'initial_scope' => lambda(&:to_i),
          'final_scope' => lambda(&:to_i)
        }.freeze

        def initialize(cycle_metrics, teams: nil)
          @cycle_metrics = cycle_metrics
          @selected_teams = teams || DEFAULT_TEAMS
        end

        def parse
          @parse ||= build_cycles_hash
        end

        def by_team
          @by_team ||= parse.values
                            .select { |c| @selected_teams.include?(c[:team]) }
                            .group_by { |c| c[:team] }
                            .transform_values { |cycles| sort_cycles(cycles) }
                            .sort_by { |team, cycles| team_sort_key(team, cycles) }
                            .to_h
        end

        private

        def build_cycles_hash
          cycles = {}

          @cycle_metrics.each do |m|
            parts = m[:metric].split(':')
            next unless parts.size == 3

            team, cycle_name, metric_name = parts
            cycle_key = "#{team}:#{cycle_name}"

            cycles[cycle_key] ||= { team: team, name: cycle_name, date: m[:date] }
            parse_metric(cycles[cycle_key], metric_name, m[:value])
          end

          cycles
        end

        def parse_metric(cycle, metric_name, value)
          parser = METRIC_PARSERS[metric_name]
          cycle[metric_name.to_sym] = parser.call(value) if parser
        end

        def sort_cycles(cycles)
          cycles.sort_by { |c| -extract_cycle_number(c[:name]) }
        end

        def extract_cycle_number(name)
          match = name.to_s.match(/Cycle\s*(\d+)/i)
          match ? match[1].to_i : 0
        end

        def team_sort_key(team, cycles)
          has_active = cycles.any? { |c| c[:status] == 'active' } ? 0 : 1
          [has_active, team]
        end
      end
    end
  end
end
