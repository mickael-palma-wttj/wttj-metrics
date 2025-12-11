# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      # Calculates commit activity by hour and day of week
      class CommitActivityCalculator
        def initialize(prs)
          @prs = prs
        end

        def calculate
          activity = Hash.new(0)

          @prs.each do |pr|
            next unless pr[:commits] && pr[:commits][:nodes]

            pr[:commits][:nodes].each do |node|
              next unless node[:commit] && node[:commit][:committedDate]

              date = DateTime.parse(node[:commit][:committedDate])
              # Format: "DayOfWeek-Hour" (e.g., "1-14" for Monday 2pm)
              # wday: 0=Sunday, 1=Monday, ..., 6=Saturday
              # hour: 0-23
              key = "#{date.wday}-#{date.hour}"
              activity[key] += 1
            end
          end

          activity.map do |key, count|
            wday, hour = key.split('-').map(&:to_i)
            {
              metric: 'commit_activity',
              date: Date.today.to_s, # Placeholder date as this is aggregated
              value: count,
              wday: wday,
              hour: hour
            }
          end
        end

        def to_rows(category)
          calculate.map do |row|
            # We use a specific category for commit activity to group them easily
            # and metric name to store wday/hour
            cat = "#{category}_commit_activity"
            metric = "#{row[:wday]}_#{row[:hour]}"
            [row[:date], cat, metric, row[:value]]
          end
        end
      end
    end
  end
end
