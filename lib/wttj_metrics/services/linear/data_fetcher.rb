# frozen_string_literal: true

module WttjMetrics
  module Services
    module Linear
      # Fetches data from Linear API
      class DataFetcher
        def initialize(cache, logger)
          @cache = cache
          @logger = logger
        end

        def call
          logger.info '📊 Fetching data from Linear...'
          client = Sources::Linear::Client.new(cache: cache)

          issues = client.fetch_all_issues
          cycles = client.fetch_cycles
          team_members = client.fetch_team_members
          workflow_states = client.fetch_workflow_states

          log_counts(issues, cycles)

          {
            issues: issues,
            cycles: cycles,
            team_members: team_members,
            workflow_states: workflow_states
          }
        end

        private

        attr_reader :cache, :logger

        def log_counts(issues, cycles)
          logger.info "   Found #{issues.size} issues"
          logger.info "   Found #{cycles.size} cycles"
        end
      end
    end
  end
end
