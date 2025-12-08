# frozen_string_literal: true

module WttjMetrics
  module Reports
    # Handles team filtering and discovery
    # Single Responsibility: Team selection logic
    class TeamFilter
      DEFAULT_TEAMS = ['ATS', 'Global ATS', 'Marketplace', 'Platform', 'ROI', 'Sourcing', 'Talents'].freeze

      def initialize(parser, teams: nil)
        @parser = parser
        @teams_param = teams
      end

      def selected_teams
        @selected_teams ||= resolve_teams
      end

      def all_teams_mode?
        @teams_param == :all
      end

      private

      def resolve_teams
        case @teams_param
        when :all
          discover_all_teams
        when nil
          DEFAULT_TEAMS
        else
          @teams_param
        end
      end

      def discover_all_teams
        @parser.metrics_for('bugs_by_team')
               .map { |m| m[:metric].split(':').first }
               .reject { |team| team.nil? || team == 'Unknown' }
               .uniq
               .sort
      end
    end
  end
end
