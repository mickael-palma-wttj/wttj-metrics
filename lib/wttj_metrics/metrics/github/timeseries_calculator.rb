# frozen_string_literal: true

require 'date'
require 'time'

module WttjMetrics
  module Metrics
    module Github
      class TimeseriesCalculator
        include Helpers::DateHelper

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
            date = parse_date(pr[:createdAt] || pr['createdAt'], format: :string)
            stats[date].record_pr(pr) if date
          end

          @releases.each do |release|
            date = parse_date(release['created_at'] || release[:created_at], format: :string)
            stats[date].record_release(release) if date
          end

          stats
        end
      end
    end
  end
end
