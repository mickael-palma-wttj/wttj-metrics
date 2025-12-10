# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Linear
      # Parses cycle metrics and organizes them by team
      # Single Responsibility: Cycle data parsing and organization
      class CycleParser
        include CycleParserConfig

        def initialize(cycle_metrics, teams: nil)
          @cycle_metrics = cycle_metrics
          @selected_teams = teams || DEFAULT_TEAMS
        end

        def parse
          @parse ||= build_cycles_hash
        end

        def by_team
          @by_team ||= build_team_grouped_cycles
        end

        private

        def build_team_grouped_cycles
          filtered_cycles
            .group_by { |cycle| cycle[:team] }
            .transform_values { |cycles| sort_cycles(cycles) }
            .sort_by { |team, cycles| team_sort_key(team, cycles) }
            .to_h
        end

        def filtered_cycles
          parse.values.select { |cycle| team_selected?(cycle[:team]) }
        end

        def team_selected?(team)
          @selected_teams.include?(team)
        end

        def build_cycles_hash
          cycles = {}

          @cycle_metrics.each do |metric_row|
            process_metric_row(metric_row, cycles)
          end

          cycles
        end

        def process_metric_row(metric_row, cycles)
          parts = parse_metric_parts(metric_row[:metric])
          return unless parts

          team, cycle_name, metric_name = parts
          cycle_key = build_cycle_key(team, cycle_name)

          cycles[cycle_key] ||= initialize_cycle(team, cycle_name, metric_row[:date])
          parse_and_store_metric(cycles[cycle_key], metric_name, metric_row[:value])
        end

        def parse_metric_parts(metric_string)
          parts = metric_string.split(':')
          parts if valid_metric_format?(parts)
        end

        def valid_metric_format?(parts)
          parts.size == METRIC_PARTS_COUNT
        end

        def build_cycle_key(team, cycle_name)
          "#{team}:#{cycle_name}"
        end

        def initialize_cycle(team, cycle_name, date)
          { team: team, name: cycle_name, date: date }
        end

        def parse_and_store_metric(cycle, metric_name, value)
          parser = metric_parser_for(metric_name)
          return unless parser

          cycle[metric_name.to_sym] = parser.call(value)
        end

        def metric_parser_for(metric_name)
          METRIC_PARSERS[metric_name]
        end

        def sort_cycles(cycles)
          cycles.sort_by { |cycle| -cycle_number(cycle) }
        end

        def cycle_number(cycle)
          extract_cycle_number(cycle[:name])
        end

        def extract_cycle_number(name)
          match = name.to_s.match(/Cycle\s*(\d+)/i)
          match ? match[1].to_i : 0
        end

        def team_sort_key(team, cycles)
          active_priority = team_has_active_cycle?(cycles) ? 0 : 1
          [active_priority, team]
        end

        def team_has_active_cycle?(cycles)
          cycles.any? { |cycle| cycle_active?(cycle) }
        end

        def cycle_active?(cycle)
          cycle[:status] == 'active'
        end
      end
    end
  end
end
