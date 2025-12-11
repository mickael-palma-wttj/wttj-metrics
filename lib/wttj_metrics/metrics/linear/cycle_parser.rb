# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Linear
      # Parses cycle metrics and organizes them by team
      # Single Responsibility: Cycle data parsing and organization
      class CycleParser
        include CycleParserConfig

        def initialize(cycle_metrics, teams: nil, teams_config: nil, available_teams: [])
          @cycle_metrics = cycle_metrics
          @selected_teams = teams || DEFAULT_TEAMS
          @teams_config = teams_config
          @available_teams = available_teams
          @matcher = Services::TeamMatcher.new(available_teams) if teams_config
        end

        def parse
          @parse ||= @teams_config ? build_aggregated_cycles_hash : build_cycles_hash
        end

        def by_team
          @by_team ||= build_team_grouped_cycles
        end

        private

        def build_team_grouped_cycles
          # If aggregated, the cycles are already filtered and keyed by UnifiedName
          # If not, we need to filter by selected_teams

          cycles_to_group = if @teams_config
                              parse.values
                            else
                              filtered_cycles
                            end

          grouped = cycles_to_group
                    .group_by { |cycle| cycle[:team] }
                    .transform_values { |cycles| sort_cycles(cycles) }
                    .sort_by { |team, cycles| team_sort_key(team, cycles) }
                    .to_h

          if @teams_config
            @teams_config.defined_teams.each do |team|
              grouped[team] ||= []
            end
          elsif @selected_teams
            @selected_teams.each do |team|
              grouped[team] ||= []
            end
          end

          grouped
        end

        def build_aggregated_cycles_hash
          raw_cycles = build_cycles_hash
          aggregated = {}

          @teams_config.defined_teams.each do |unified_name|
            patterns = @teams_config.patterns_for(unified_name, :linear)
            source_teams = @matcher.match(patterns)

            # Find all cycles for these source teams
            cycles_by_name = Hash.new { |h, k| h[k] = [] }
            source_teams.each do |team|
              # Find cycles for this team in raw_cycles
              # raw_cycles keys are "Team:CycleName"
              # We can iterate raw_cycles or optimize
              # Optimization: iterate raw_cycles once? No, let's just iterate.
              raw_cycles.each_value do |cycle|
                cycles_by_name[cycle[:name]] << cycle if cycle[:team] == team
              end
            end

            # Aggregate
            cycles_by_name.each do |cycle_name, cycles|
              next if cycles.empty?

              aggregated["#{unified_name}:#{cycle_name}"] = aggregate_cycles(unified_name, cycle_name, cycles)
            end
          end

          aggregated
        end

        def aggregate_cycles(unified_name, _cycle_name, cycles)
          base = cycles.first.dup
          base[:team] = unified_name

          # Sum metrics
          %w[total_issues completed_issues bug_count velocity planned_points carryover initial_scope final_scope
             assignee_count].each do |metric|
            base[metric.to_sym] = cycles.sum { |c| c[metric.to_sym].to_i }
          end

          # Recalculate derived metrics
          base[:completion_rate] = calculate_rate(base[:completed_issues], base[:total_issues])
          base[:progress] = calculate_rate(base[:completed_issues], base[:total_issues])
          base[:scope_change] = calculate_change(base[:final_scope], base[:initial_scope])

          # Average duration? Or just take first? Assuming same cycle duration.
          # base[:duration_days] = cycles.map { |c| c[:duration_days].to_i }.max # Max duration?

          base
        end

        def calculate_rate(numerator, denominator)
          return 0 if denominator.to_i.zero?

          ((numerator.to_f / denominator) * 100).round
        end

        def calculate_change(final, initial)
          return 0 if initial.to_i.zero?

          ((final.to_f - initial) / initial * 100).round
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
