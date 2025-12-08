# frozen_string_literal: true

module WttjMetrics
  module Reports
    # Builds weekly bug flow data aggregated by team
    # Single Responsibility: Weekly bug metrics aggregation
    class WeeklyBugFlowBuilder
      def initialize(parser, selected_teams, cutoff_date)
        @parser = parser
        @selected_teams = selected_teams
        @cutoff_date = cutoff_date
        @weekly_aggregator = WeeklyDataAggregator.new(cutoff_date)
      end

      def build_flow_data
        team_aggregator = Services::TeamMetricsAggregator.new(@parser, @selected_teams, @cutoff_date)
        aggregated = team_aggregator.aggregate_timeseries('bugs_created', 'bugs_closed')

        result = @weekly_aggregator.aggregate_pair(
          aggregated[:created],
          aggregated[:completed],
          labels: %i[created closed]
        )

        remap_keys(result)
      end

      def build_by_team_data(base_labels)
        team_data = @selected_teams.each_with_object({}) do |team, data|
          created = @parser.timeseries_for("bugs_created_#{team}", since: @cutoff_date)
          week_counts = build_week_counts(created)
          values = base_labels.map { |label| week_counts[label] || 0 }

          data[team] = { created: values, closed: [] }
        end

        { labels: base_labels, teams: team_data }
      end

      private

      def remap_keys(result)
        {
          labels: result[:labels],
          created: result[:created_raw],
          closed: result[:closed_raw],
          created_pct: result[:created_pct],
          closed_pct: result[:closed_pct]
        }
      end

      def build_week_counts(metrics)
        return {} if metrics.empty?

        metrics.each_with_object(Hash.new(0)) do |m, counts|
          week_label = calculate_week_label(m[:date])
          counts[week_label] += m[:value].to_i
        end
      end

      def calculate_week_label(date_string)
        date = Date.parse(date_string)
        monday = date - ((date.wday - 1) % 7)
        monday.strftime('%b %d')
      end
    end
  end
end
