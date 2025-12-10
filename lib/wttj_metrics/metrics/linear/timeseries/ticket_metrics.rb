# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      module Timeseries
        # Tracks ticket creation and completion metrics per date
        class TicketMetrics
          def initialize
            @created_per_day = Hash.new(0)
            @completed_per_day = Hash.new(0)
            @created_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
            @completed_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
          end

          def record_creation(date, issue)
            @created_per_day[date] += 1
            team = issue.dig('team', 'name') || 'Unknown'
            @created_by_team[date][team] += 1
          end

          def record_completion(date, issue)
            @completed_per_day[date] += 1
            team = issue.dig('team', 'name') || 'Unknown'
            @completed_by_team[date][team] += 1
          end

          def to_rows(category)
            rows = @created_per_day.map do |date, count|
              [date, category, 'tickets_created', count]
            end

            @completed_per_day.each do |date, count|
              rows << [date, category, 'tickets_completed', count]
            end

            @created_by_team.each do |date, teams|
              teams.each do |team, count|
                rows << [date, category, "tickets_created_#{team}", count]
              end
            end

            @completed_by_team.each do |date, teams|
              teams.each do |team, count|
                rows << [date, category, "tickets_completed_#{team}", count]
              end
            end

            rows
          end
        end
      end
    end
  end
end
