# frozen_string_literal: true

module WttjMetrics
  module Services
    # Service object for aggregating team-specific metrics
    # Single Responsibility: Team data aggregation
    class TeamMetricsAggregator
      def initialize(parser, teams, cutoff_date)
        @parser = parser
        @teams = teams
        @cutoff_date = cutoff_date
      end

      def aggregate_timeseries(prefix_created, prefix_completed)
        created_by_date = aggregate_metric_by_date("#{prefix_created}_")
        completed_by_date = aggregate_metric_by_date("#{prefix_completed}_")

        {
          created: hash_to_array(created_by_date),
          completed: hash_to_array(completed_by_date)
        }
      end

      private

      def aggregate_metric_by_date(metric_prefix)
        aggregated = Hash.new(0)

        @teams.each do |team|
          metric_name = "#{metric_prefix}#{team}"
          @parser.timeseries_for(metric_name, since: @cutoff_date).each do |m|
            aggregated[m[:date]] += m[:value].to_i
          end
        end

        aggregated
      end

      def hash_to_array(hash)
        hash.map { |date, value| { date: date, value: value } }
      end
    end
  end
end
