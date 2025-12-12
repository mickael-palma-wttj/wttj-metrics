# frozen_string_literal: true

module WttjMetrics
  module Services
    class TeamMatcher
      def initialize(available_teams)
        @available_teams = available_teams
      end

      def match(patterns)
        patterns = [patterns] unless patterns.is_a?(Array)

        patterns.flat_map do |pattern|
          @available_teams.select do |team|
            File.fnmatch(pattern, team, File::FNM_CASEFOLD)
          end
        end.uniq
      end
    end
  end
end
