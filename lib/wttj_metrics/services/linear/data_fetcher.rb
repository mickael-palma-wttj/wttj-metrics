# frozen_string_literal: true

module WttjMetrics
  module Services
    module Linear
      # Fetches data from Linear API
      class DataFetcher
        def initialize(cache, logger, start_date = nil, end_date = nil)
          @cache = cache
          @logger = logger
          @start_date = start_date || (Date.today - 90)
          @end_date = end_date || Date.today
        end

        def call
          logger.info '📊 Fetching data from Linear...'
          client = Sources::Linear::Client.new(cache: cache)

          all_issues = client.fetch_all_issues
          all_cycles = client.fetch_cycles
          team_members = client.fetch_team_members
          workflow_states = client.fetch_workflow_states

          issues = filter_issues(all_issues)
          cycles = filter_cycles(all_cycles)

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

        def filter_issues(issues)
          from_date = @start_date.iso8601
          to_date = (@end_date + 1).iso8601

          issues.select do |issue|
            created_at = issue['createdAt']
            created_at && created_at >= from_date && created_at < to_date
          end
        end

        def filter_cycles(cycles)
          from_date = @start_date.iso8601
          to_date = (@end_date + 1).iso8601

          cycles.select do |cycle|
            starts_at = cycle['startsAt']
            ends_at = cycle['endsAt']
            next false unless starts_at && ends_at

            # Include cycle if it overlaps with the date range
            starts_at < to_date && ends_at >= from_date
          end
        end

        def log_counts(issues, cycles)
          logger.info "   Found #{issues.size} issues (#{@start_date} to #{@end_date})"
          logger.info "   Found #{cycles.size} cycles"
        end
      end
    end
  end
end
