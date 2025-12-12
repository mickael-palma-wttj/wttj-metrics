# frozen_string_literal: true

module WttjMetrics
  module Reports
    module Github
      # Handles team discovery and filtering
      class TeamService
        def initialize(parser, config)
          @parser = parser
          @config = config
        end

        def resolve_teams
          available_teams = fetch_available_teams

          if @config
            filter_teams_by_config(available_teams)
          else
            available_teams
          end
        end

        private

        def fetch_available_teams
          keys = @parser.metrics_by_category.keys.select do |k|
            k.start_with?('github:') &&
              !k.end_with?('_daily', '_repo_activity', '_contributor_activity', '_commit_activity')
          end

          keys.map { |k| k.split(':').last }
        end

        def filter_teams_by_config(available_teams)
          @config.defined_teams.flat_map do |unified_name|
            patterns = @config.patterns_for(unified_name, :github)
            Services::TeamMatcher.new(available_teams).match(patterns)
          end.uniq
        end
      end
    end
  end
end
