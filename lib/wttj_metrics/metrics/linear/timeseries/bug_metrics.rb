# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      module Timeseries
        # Tracks bug-specific metrics including MTTR
        class BugMetrics
          include Helpers::Linear::IssueHelper

          COMPLETED_STATES = %w[completed canceled].freeze

          def initialize
            @created_per_day = Hash.new(0)
            @closed_per_day = Hash.new(0)
            @created_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
            @closed_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
            @stats_by_team = Hash.new do |h, k|
              h[k] = { created: 0, closed: 0, open: 0, resolution_times: [] }
            end
          end

          def record_creation(date, issue)
            return unless issue_is_bug?(issue)

            @created_per_day[date] += 1
            team = issue.dig('team', 'name') || 'Unknown'
            @created_by_team[date][team] += 1
          end

          def record_completion(date, issue)
            return unless issue_is_bug?(issue)

            @closed_per_day[date] += 1
            team = issue.dig('team', 'name') || 'Unknown'
            @closed_by_team[date][team] += 1
          end

          def record_team_stats(issue)
            return unless issue_is_bug?(issue)

            team = issue.dig('team', 'name') || 'Unknown'
            @stats_by_team[team][:created] += 1

            if completed_state?(issue)
              @stats_by_team[team][:closed] += 1
              record_resolution_time(issue, team)
            else
              @stats_by_team[team][:open] += 1
            end
          end

          def to_rows(category)
            rows = @created_per_day.map do |date, count|
              [date, category, 'bugs_created', count]
            end

            @closed_per_day.each do |date, count|
              rows << [date, category, 'bugs_closed', count]
            end

            @created_by_team.each do |date, teams|
              teams.each do |team, count|
                rows << [date, category, "bugs_created_#{team}", count]
              end
            end

            @closed_by_team.each do |date, teams|
              teams.each do |team, count|
                rows << [date, category, "bugs_closed_#{team}", count]
              end
            end

            rows
          end

          attr_reader :stats_by_team

          private

          def completed_state?(issue)
            COMPLETED_STATES.include?(issue.dig('state', 'type'))
          end

          def record_resolution_time(issue, team)
            return unless issue['completedAt']

            created = parse_datetime(issue['createdAt'])
            completed = parse_datetime(issue['completedAt'])
            resolution_days = (completed - created).to_f
            @stats_by_team[team][:resolution_times] << resolution_days
          end

          def parse_datetime(datetime_string)
            DateTime.parse(datetime_string)
          end
        end
      end
    end
  end
end
