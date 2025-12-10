# frozen_string_literal: true

require 'date'
require 'time'

module WttjMetrics
  module Metrics
    module Github
      class TimeseriesCalculator
        CATEGORY = 'github_daily'

        def initialize(pull_requests, releases = [])
          @pull_requests = pull_requests
          @releases = releases || []
        end

        def to_rows
          stats_by_date.flat_map do |date, stats|
            stats.to_rows(date, CATEGORY)
          end
        end

        private

        def stats_by_date
          stats = Hash.new { |h, k| h[k] = Timeseries::DailyStats.new }

          @pull_requests.each do |pr|
            date = parse_date(pr[:createdAt] || pr['createdAt'])
            stats[date].record_pr(pr) if date
          end

          @releases.each do |release|
            date = parse_date(release['created_at'] || release[:created_at])
            stats[date].record_release(release) if date
          end

          stats
        end

        def parse_date(date_str)
          return nil unless date_str

          Date.parse(date_str.to_s).to_s
        rescue Date::Error
          nil
        end
      end
    end
  end
end
