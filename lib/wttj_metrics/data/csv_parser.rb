# frozen_string_literal: true

require 'csv'
require 'date'

module WttjMetrics
  module Data
    # Parses CSV metrics data and provides access to metrics by category
    # Single Responsibility: Only handles CSV parsing and data organization
    class CsvParser
      attr_reader :data, :metrics_by_category, :today

      def initialize(csv_path)
        @csv_path = csv_path
        @today = Date.today.to_s
        @data = CSV.read(csv_path, headers: true, liberal_parsing: true)
        parse_metrics
      end

      def metrics_for(category, date: nil)
        date ||= @today
        @metrics_by_category[category]&.select { |m| m[:date] == date } || []
      end

      def timeseries_for(metric_name, since:)
        @metrics_by_category['timeseries']
          &.select { |m| m[:metric] == metric_name && m[:date] >= since } || []
      end

      private

      def parse_metrics
        @metrics_by_category = Hash.new { |h, k| h[k] = [] }

        @data.each do |row|
          @metrics_by_category[row['category']] << build_metric(row)
        end
      end

      def build_metric(row)
        {
          date: row['date'],
          metric: row['metric'],
          value: parse_value(row)
        }
      end

      def parse_value(row)
        return row['value'] if %w[cycle type_breakdown github_commit_activity
                                  linear_ticket_activity].include?(row['category'])

        row['value'].to_f
      end
    end
  end
end
