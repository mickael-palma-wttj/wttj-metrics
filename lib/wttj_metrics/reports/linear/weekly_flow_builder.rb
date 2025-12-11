# frozen_string_literal: true

module WttjMetrics
  module Reports
    module Linear
      class WeeklyFlowBuilder
        def initialize(parser, teams, cutoff_date, teams_config: nil, available_teams: [])
          @parser = parser
          @teams = teams
          @cutoff_date = cutoff_date
          @teams_config = teams_config
          @available_teams = available_teams
          @aggregator = WeeklyDataAggregator.new(cutoff_date)
          @matcher = Services::TeamMatcher.new(available_teams) if teams_config
        end

        def build_flow_data
          data = build_data('tickets_created', 'tickets_completed')
          format_flow_data(data)
        end

        def build_bug_flow_data
          data = build_data('bugs_created', 'bugs_closed', labels: %i[created closed])
          format_bug_data(data)
        end

        def build_bug_flow_by_team_data(base_labels)
          team_data = @teams.each_with_object({}) do |team, acc|
            acc[team] = build_team_bug_data(team, base_labels)
          end

          { labels: base_labels, teams: team_data }
        end

        private

        def build_data(created_prefix, completed_prefix, labels: %i[created completed])
          created = sum_metrics_by_date(created_prefix)
          completed = sum_metrics_by_date(completed_prefix)

          @aggregator.aggregate_pair(created, completed, labels: labels)
        end

        def sum_metrics_by_date(metric_prefix)
          by_date = Hash.new(0)
          @teams.each do |team|
            resolve_source_teams(team).each do |source_team|
              @parser.timeseries_for("#{metric_prefix}_#{source_team}", since: @cutoff_date).each do |m|
                by_date[m[:date]] += m[:value].to_i
              end
            end
          end
          by_date.map { |date, value| { date: date, value: value } }
        end

        def resolve_source_teams(team)
          return [team] unless @teams_config

          patterns = @teams_config.patterns_for(team, :linear)
          return [team] if patterns.empty?

          @matcher.match(patterns)
        end

        def build_team_bug_data(team, base_labels)
          created = @parser.timeseries_for("bugs_created_#{team}", since: @cutoff_date)
          week_counts = build_week_counts(created)
          values = base_labels.map { |label| week_counts[label] || 0 }

          { created: values, closed: [] }
        end

        def build_week_counts(metrics)
          metrics.each_with_object(Hash.new(0)) do |m, counts|
            label = week_label_for(m[:date])
            counts[label] += m[:value].to_i
          end
        end

        def week_label_for(date_string)
          date = Date.parse(date_string)
          monday = date - ((date.wday - 1) % 7)
          monday.strftime('%b %d')
        end

        def format_flow_data(data)
          {
            labels: data[:labels],
            created_pct: data[:created_pct],
            completed_pct: data[:completed_pct],
            created_raw: data[:created_raw],
            completed_raw: data[:completed_raw]
          }
        end

        def format_bug_data(data)
          {
            labels: data[:labels],
            created: data[:created_raw],
            closed: data[:closed_raw],
            created_pct: data[:created_pct],
            closed_pct: data[:closed_pct]
          }
        end
      end
    end
  end
end
