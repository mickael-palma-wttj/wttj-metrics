# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Linear
      # Calculates ticket completion activity by hour and day of week
      class TicketActivityCalculator
        def initialize(issues)
          @issues = issues
        end

        def calculate
          activity = Hash.new(0)

          @issues.each do |issue|
            next unless issue['completedAt']

            date = DateTime.parse(issue['completedAt'])
            # Format: "DayOfWeek-Hour" (e.g., "1-14" for Monday 2pm)
            # wday: 0=Sunday, 1=Monday, ..., 6=Saturday
            # hour: 0-23
            key = "#{date.wday}-#{date.hour}"
            activity[key] += 1
          end

          activity.map do |key, count|
            wday, hour = key.split('-').map(&:to_i)
            {
              metric: 'ticket_activity',
              date: Date.today.to_s, # Placeholder date as this is aggregated
              value: count,
              wday: wday,
              hour: hour
            }
          end
        end

        def to_rows
          calculate.map do |row|
            # We use a specific category for ticket activity to group them easily
            # and metric name to store wday/hour
            cat = 'linear_ticket_activity'
            metric = "#{row[:wday]}_#{row[:hour]}"
            [row[:date], cat, metric, row[:value]]
          end
        end
      end
    end
  end
end
