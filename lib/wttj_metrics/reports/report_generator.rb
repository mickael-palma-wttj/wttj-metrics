# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'

module WttjMetrics
  module Reports
    # Generates HTML and Excel reports from CSV metrics data
    # Facade pattern: Coordinates multiple specialized classes
    class ReportGenerator
      SELECTED_TEAMS = ['ATS', 'Global ATS', 'Marketplace', 'Platform', 'ROI', 'Sourcing', 'Talents'].freeze

      STATE_CATEGORIES = {
        'Backlog' => %w[Backlog Triage],
        'Todo' => ['Todo', 'To Do', 'To do'],
        'In Progress' => ['In Progress', 'In progress', 'To dev', 'To design'],
        'In Review' => ['In Review', 'In review', 'Code review', 'To Review', 'Ok for Merge', 'Ok for merge',
                        'To Merge (main)'],
        'Testing' => ['To test', 'To Validate', 'Qualified', 'To Deploy (PROD)', 'OK for release'],
        'Done' => %w[Done Released],
        'Canceled' => %w[Canceled Auto-closed Duplicate Archived Stalled]
      }.freeze

      STATUS_GROUPS = {
        'Backlog' => %w[Backlog Triage Archived],
        'To Do' => ['Todo', 'To Do', 'To do', 'To design', 'To dev', 'To Qualify'],
        'In Progress' => ['In Progress', 'In progress'],
        'In Review' => ['In Review', 'To Review', 'To test', 'To Validate', 'To Merge (main)'],
        'Done' => %w[Done Released Canceled Duplicate Auto-closed]
      }.freeze

      attr_reader :data, :metrics_by_category, :days_to_show, :today, :selected_teams, :all_teams_mode

      def initialize(csv_path, days: 90, teams: nil)
        @csv_path = csv_path
        @days_to_show = days
        @today = Date.today.to_s
        @parser = Data::CsvParser.new(csv_path)
        @data = @parser.data
        @metrics_by_category = @parser.metrics_by_category

        # Handle teams parameter: :all means discover all teams, nil means default, array means custom
        @all_teams_mode = teams == :all
        @selected_teams = if teams == :all
                            discover_all_teams
                          else
                            teams || SELECTED_TEAMS
                          end
      end

      def generate_html(output_path)
        html = build_html
        File.write(output_path, html)
        puts "✅ HTML report generated: #{output_path}"
      end

      def generate_excel(output_path)
        builder = Reports::ExcelReportBuilder.new(excel_report_data)
        builder.build(output_path)
        puts "✅ Excel report generated: #{output_path}"
      end

      # Metric accessors with presenters (memoized)
      def flow_metrics
        @flow_metrics ||= @parser.metrics_for('flow')
      end

      def flow_metrics_presented
        @flow_metrics_presented ||= flow_metrics.map { |m| Presenters::FlowMetricPresenter.new(m) }
      end

      def cycle_metrics
        @cycle_metrics ||= @parser.metrics_for('cycle_metrics')
      end

      def cycle_metrics_presented
        @cycle_metrics_presented ||= cycle_metrics.map { |m| Presenters::CycleMetricPresenter.new(m) }
      end

      def team_metrics
        @team_metrics ||= @parser.metrics_for('team')
      end

      def team_metrics_presented
        @team_metrics_presented ||= team_metrics.map { |m| Presenters::TeamMetricPresenter.new(m) }
      end

      def bug_metrics
        @bug_metrics ||= @parser.metrics_for('bugs')
      end

      def bug_metrics_presented
        @bug_metrics_presented ||= bug_metrics.map { |m| Presenters::BugMetricPresenter.new(m) }
      end

      def bugs_by_priority
        @bugs_by_priority ||= @parser.metrics_for('bugs_by_priority')
      end

      def bugs_by_team
        @bugs_by_team ||= build_bugs_by_team
      end

      def bugs_by_team_presented
        @bugs_by_team_presented ||= bugs_by_team.map { |team, stats| Presenters::BugTeamPresenter.new(team, stats) }
      end

      def status_dist
        @status_dist ||= @parser.metrics_for('status')
      end

      def priority_dist
        @priority_dist ||= @parser.metrics_for('priority')
      end

      def type_dist
        @type_dist ||= @parser.metrics_for('type')
      end

      def assignee_dist
        @assignee_dist ||= @parser.metrics_for('assignee')
                                  .sort_by { |m| -m[:value] }
                                  .first(15)
      end

      def weekly_flow_data
        @weekly_flow_data ||= build_weekly_flow_data
      end

      def weekly_bug_flow_data
        @weekly_bug_flow_data ||= build_weekly_bug_flow_data
      end

      def weekly_bug_flow_by_team_data
        @weekly_bug_flow_by_team_data ||= build_weekly_bug_flow_by_team_data
      end

      def transition_weekly_data
        @transition_weekly_data ||= build_transition_data
      end

      def status_chart_data
        @status_chart_data ||= Reports::ChartDataBuilder.new(@parser).status_chart_data
      end

      def priority_chart_data
        priority_dist.map { |m| { label: m[:metric], value: m[:value].to_i } }
      end

      def type_chart_data
        type_dist.map { |m| { label: m[:metric], value: m[:value].to_i } }
      end

      def assignee_chart_data
        assignee_dist.map { |m| { label: m[:metric], value: m[:value].to_i } }
      end

      def cycles_parsed
        # Filter cycles by cutoff date to respect days parameter
        filtered_cycles = @metrics_by_category['cycle']&.select { |m| m[:date] >= cutoff_date } || []
        @cycles_parsed ||= Metrics::CycleParser.new(filtered_cycles, teams: @selected_teams).parse
      end

      def cycles_by_team
        # Filter cycles by cutoff date to respect days parameter
        filtered_cycles = @metrics_by_category['cycle']&.select { |m| m[:date] >= cutoff_date } || []
        @cycles_by_team ||= Metrics::CycleParser.new(filtered_cycles, teams: @selected_teams).by_team
      end

      def cycles_by_team_presented
        @cycles_by_team_presented ||= cycles_by_team.transform_values do |cycles|
          cycles.map { |c| Presenters::CyclePresenter.new(c) }
        end
      end

      def team_stats
        @team_stats ||= Metrics::TeamStatsCalculator.new(cycles_by_team).calculate
      end

      private

      def cutoff_date
        @cutoff_date ||= (Date.today - @days_to_show).to_s
      end

      def discover_all_teams
        # Extract unique team names from bugs_by_team metrics (format: "Team:stat")
        teams = Set.new
        @parser.metrics_for('bugs_by_team').each do |m|
          team = m[:metric].split(':').first
          teams << team if team && team != 'Unknown'
        end
        teams.to_a.sort
      end

      def build_bugs_by_team
        raw_data = @parser.metrics_for('bugs_by_team')
        teams = {}

        raw_data.each do |m|
          team, stat = m[:metric].split(':')
          next unless @selected_teams.include?(team)

          teams[team] ||= { created: 0, closed: 0, open: 0 }
          teams[team][stat.to_sym] = m[:value].to_i
        end

        teams.sort_by { |_, v| -v[:open] }.to_h
      end

      def build_weekly_flow_data
        aggregator = Reports::WeeklyDataAggregator.new(cutoff_date)

        # Aggregate tickets only from selected teams
        created_by_date = Hash.new(0)
        completed_by_date = Hash.new(0)

        @selected_teams.each do |team|
          @parser.timeseries_for("tickets_created_#{team}", since: cutoff_date).each do |m|
            created_by_date[m[:date]] += m[:value].to_i
          end
          @parser.timeseries_for("tickets_completed_#{team}", since: cutoff_date).each do |m|
            completed_by_date[m[:date]] += m[:value].to_i
          end
        end

        # Convert back to array format expected by aggregator
        created = created_by_date.map { |date, value| { date: date, value: value } }
        completed = completed_by_date.map { |date, value| { date: date, value: value } }

        result = aggregator.aggregate_pair(created, completed, labels: %i[created completed])

        # Remap keys for backwards compatibility
        {
          labels: result[:labels],
          created_pct: result[:created_pct],
          completed_pct: result[:completed_pct],
          created_raw: result[:created_raw],
          completed_raw: result[:completed_raw]
        }
      end

      def build_weekly_bug_flow_data
        aggregator = Reports::WeeklyDataAggregator.new(cutoff_date)

        # Aggregate bugs only from selected teams
        created_by_date = Hash.new(0)
        closed_by_date = Hash.new(0)

        @selected_teams.each do |team|
          @parser.timeseries_for("bugs_created_#{team}", since: cutoff_date).each do |m|
            created_by_date[m[:date]] += m[:value].to_i
          end
          @parser.timeseries_for("bugs_closed_#{team}", since: cutoff_date).each do |m|
            closed_by_date[m[:date]] += m[:value].to_i
          end
        end

        # Convert back to array format expected by aggregator
        created = created_by_date.map { |date, value| { date: date, value: value } }
        closed = closed_by_date.map { |date, value| { date: date, value: value } }

        result = aggregator.aggregate_pair(created, closed, labels: %i[created closed])

        {
          labels: result[:labels],
          created: result[:created_raw],
          closed: result[:closed_raw],
          created_pct: result[:created_pct],
          closed_pct: result[:closed_pct]
        }
      end

      def build_weekly_bug_flow_by_team_data
        # Use the same labels as the main bug flow chart for consistency
        base_labels = weekly_bug_flow_data[:labels]

        team_data = {}

        @selected_teams.each do |team|
          created = @parser.timeseries_for("bugs_created_#{team}", since: cutoff_date)

          # Build a hash of week -> count from the team's data
          week_counts = build_week_counts(created)

          # Map to the base labels, filling zeros for missing weeks
          values = base_labels.map { |label| week_counts[label] || 0 }

          team_data[team] = {
            created: values,
            closed: [] # Not used in current chart
          }
        end

        {
          labels: base_labels,
          teams: team_data
        }
      end

      def build_week_counts(metrics)
        return {} if metrics.empty?

        week_counts = Hash.new(0)

        metrics.each do |m|
          date = Date.parse(m[:date])
          # Calculate Monday of the week (handles all edge cases including Week 00)
          monday = date - ((date.wday - 1) % 7)
          label = monday.strftime('%b %d')
          week_counts[label] += m[:value].to_i
        end

        week_counts
      end

      def build_transition_data
        TransitionDataBuilder.new(@metrics_by_category['transition_to'], cutoff_date, teams: @selected_teams).build
      end

      def state_to_category
        @state_to_category ||= STATE_CATEGORIES.each_with_object({}) do |(cat, states), lookup|
          states.each { |s| lookup[s] = cat }
        end
      end

      def build_html
        template_path = File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'report.html.erb')

        if File.exist?(template_path)
          template = ERB.new(File.read(template_path))
          template.result(binding)
        else
          build_html_fallback
        end
      end

      def build_html_fallback
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head><title>Linear Metrics - #{@today}</title></head>
          <body>
            <h1>Linear Metrics Dashboard</h1>
            <p>Generated: #{@today}</p>
            <p>Please run with the proper template file.</p>
          </body>
          </html>
        HTML
      end

      def excel_report_data
        {
          today: @today,
          days_to_show: @days_to_show,
          flow_metrics: flow_metrics,
          cycle_metrics: cycle_metrics,
          team_metrics: team_metrics,
          bug_metrics: bug_metrics,
          bugs_by_priority: bugs_by_priority,
          status_chart_data: status_chart_data,
          priority_dist: priority_dist,
          type_dist: type_dist,
          assignee_dist: assignee_dist,
          team_stats: team_stats,
          cycles_by_team: cycles_by_team,
          weekly_flow_data: weekly_flow_data,
          raw_data: @data
        }
      end
    end

    # Builds transition data for state flow charts
    class TransitionDataBuilder
      def initialize(transition_metrics, cutoff_date, teams: nil)
        @transition_metrics = transition_metrics || []
        @cutoff_date = cutoff_date
        @teams = teams
        @state_to_category = build_state_lookup
      end

      def build
        transition_data = aggregate_transitions
        transition_weekly = group_by_week(transition_data)

        build_result(transition_weekly, transition_data)
      end

      private

      def build_state_lookup
        Reports::ReportGenerator::STATE_CATEGORIES.each_with_object({}) do |(cat, states), lookup|
          states.each { |s| lookup[s] = cat }
        end
      end

      def aggregate_transitions
        filtered_metrics = @transition_metrics.select { |m| m[:date] >= @cutoff_date }

        # Filter by teams if specified (metrics are in format "Team:State" or just "State")
        if @teams
          team_metrics = filtered_metrics.select do |m|
            metric = m[:metric]
            if metric.include?(':')
              team = metric.split(':').first
              @teams.include?(team)
            else
              false # Skip non-team-specific metrics when filtering
            end
          end

          # Extract just the state part from "Team:State"
          mapped_metrics = team_metrics.map do |m|
            state = m[:metric].split(':').last
            { date: m[:date], state: @state_to_category[state] || 'Other', value: m[:value].to_i }
          end

          mapped_metrics.group_by { |m| m[:date] }
                        .transform_values { |arr| aggregate_by_state(arr) }
        else
          # No team filter, use all non-team-specific metrics
          filtered_metrics
            .reject { |m| m[:metric].include?(':') }
            .map { |m| { date: m[:date], state: @state_to_category[m[:metric]] || 'Other', value: m[:value].to_i } }
            .group_by { |m| m[:date] }
            .transform_values { |arr| aggregate_by_state(arr) }
        end
      end

      def aggregate_by_state(arr)
        arr.group_by { |m| m[:state] }
           .transform_values { |v| v.sum { |x| x[:value] } }
      end

      def group_by_week(transition_data)
        transition_data.keys.sort.group_by { |d| Date.parse(d).strftime('%Y-W%W') }
      end

      def build_result(transition_weekly, transition_data)
        labels = []
        datasets = Hash.new { |h, k| h[k] = { percentages: [], raw: [] } }

        transition_weekly.sort.each do |week, dates|
          labels << format_week_label(week, dates)
          week_totals = calculate_week_totals(dates, transition_data)
          populate_datasets(datasets, week_totals)
        end

        { labels: labels, datasets: datasets }
      end

      def format_week_label(week, dates)
        Date.strptime("#{week}-1", '%Y-W%W-1').strftime('%b %d')
      rescue StandardError
        Date.parse(dates.first).strftime('%b %d')
      end

      def calculate_week_totals(dates, transition_data)
        totals = Hash.new(0)
        dates.each do |d|
          (transition_data[d] || {}).each { |state, val| totals[state] += val }
        end
        totals
      end

      def populate_datasets(datasets, week_totals)
        total = week_totals.values.sum

        Reports::ReportGenerator::STATE_CATEGORIES.each_key do |state|
          raw_val = week_totals[state]
          pct = total.positive? ? ((raw_val.to_f / total) * 100).round(1) : 0
          datasets[state][:percentages] << pct
          datasets[state][:raw] << raw_val
        end
      end
    end
  end
end
