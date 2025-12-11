# frozen_string_literal: true

module WttjMetrics
  module Reports
    module Linear
      # Builds bugs-by-team statistics
      # Single Responsibility: Aggregate bug metrics by team
      class BugsByTeamBuilder
        def initialize(data_provider, selected_teams)
          @data_provider = data_provider
          @selected_teams = selected_teams
        end

        def build
          raw_data = @data_provider.metrics_for('bugs_by_team')
          teams = aggregate_team_data(raw_data)
          sort_by_open_bugs(teams)
        end

        private

        def aggregate_team_data(raw_data)
          raw_data.each_with_object({}) do |metric, teams|
            team, stat = parse_metric(metric[:metric])
            next unless team_selected?(team)

            teams[team] ||= default_stats
            teams[team][stat.to_sym] = parse_value(stat, metric[:value])
          end
        end

        def parse_metric(metric)
          metric.split(':')
        end

        def team_selected?(team)
          @selected_teams.include?(team)
        end

        def default_stats
          { created: 0, closed: 0, open: 0, mttr: 0 }
        end

        def parse_value(stat, value)
          stat == 'mttr' ? value.to_f.round : value.to_i
        end

        def sort_by_open_bugs(teams)
          teams.sort_by { |_, stats| -stats[:open] }.to_h
        end
      end
    end
  end
end
