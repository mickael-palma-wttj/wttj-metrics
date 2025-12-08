# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'
require 'logger'
require 'forwardable'

module WttjMetrics
  # Generates HTML and Excel reports from CSV metrics data
  # Facade pattern: Coordinates multiple specialized classes
  class ReportGenerator
    extend Forwardable

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

    # Delegate metric access to MetricAccessor
    def_delegators :@metric_accessor, :flow_metrics, :flow_metrics_presented, :cycle_metrics,
                   :cycle_metrics_presented, :team_metrics, :team_metrics_presented,
                   :bug_metrics, :bug_metrics_presented, :bugs_by_priority,
                   :status_dist, :priority_dist, :type_dist, :assignee_dist

    def initialize(csv_path, days: 90, teams: nil)
      @csv_path = csv_path
      @days_to_show = days
      @today = Date.today.to_s
      @parser = Data::CsvParser.new(csv_path)
      @data = @parser.data
      @metrics_by_category = @parser.metrics_by_category
      @logger = Logger.new($stdout)
      @logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }

      # Initialize team filter
      @team_filter = Reports::TeamFilter.new(@parser, teams: teams)
      @all_teams_mode = @team_filter.all_teams_mode?
      @selected_teams = @team_filter.selected_teams

      # Initialize metric accessor
      @metric_accessor = Reports::MetricAccessor.new(@parser)
    end

    def generate_html(output_path)
      generator = Reports::HtmlGenerator.new(self)
      generator.generate(output_path)
      @logger.info "✅ HTML report generated: #{output_path}"
    end

    def generate_excel(output_path)
      builder = Reports::ExcelReportBuilder.new(excel_report_data)
      builder.build(output_path)
      @logger.info "✅ Excel report generated: #{output_path}"
    end

    def bugs_by_team
      @bugs_by_team ||= Reports::BugsByTeamBuilder.new(@parser, @selected_teams).build
    end

    def bugs_by_team_presented
      @bugs_by_team_presented ||= Services::PresenterMapper.map_team_stats_to_presenters(
        bugs_by_team, Presenters::BugTeamPresenter
      )
    end

    def weekly_flow_data
      @weekly_flow_data ||= build_weekly_flow_data
    end

    def weekly_bug_flow_data
      @weekly_bug_flow_data ||= bug_flow_builder.build_flow_data
    end

    def weekly_bug_flow_by_team_data
      @weekly_bug_flow_by_team_data ||= bug_flow_builder.build_by_team_data(weekly_bug_flow_data[:labels])
    end

    def transition_weekly_data
      @transition_weekly_data ||= build_transition_data
    end

    def status_chart_data
      @status_chart_data ||= chart_builder.status_chart_data
    end

    def priority_chart_data
      @priority_chart_data ||= chart_builder.priority_chart_data
    end

    def type_chart_data
      @type_chart_data ||= chart_builder.type_chart_data
    end

    def assignee_chart_data
      @assignee_chart_data ||= chart_builder.assignee_chart_data
    end

    def cycles_parsed
      @cycles_parsed ||= create_cycle_parser(@parser.metrics_for('cycle', date: nil)).parse
    end

    def cycles_by_team
      @cycles_by_team ||= create_cycle_parser(@metrics_by_category['cycle']).by_team
    end

    def cycles_by_team_presented
      @cycles_by_team_presented ||= Services::PresenterMapper.map_hash_to_presenters(
        cycles_by_team, Presenters::CyclePresenter
      )
    end

    def team_stats
      @team_stats ||= Metrics::TeamStatsCalculator.new(cycles_by_team).calculate
    end

    private

    def cutoff_date
      @cutoff_date ||= (Date.today - @days_to_show).to_s
    end

    def chart_builder
      @chart_builder ||= Reports::ChartDataBuilder.new(@parser)
    end

    def bug_flow_builder
      @bug_flow_builder ||= Reports::WeeklyBugFlowBuilder.new(@parser, @selected_teams, cutoff_date)
    end

    def create_cycle_parser(metrics)
      Metrics::CycleParser.new(metrics, teams: @selected_teams)
    end

    def build_weekly_flow_data
      team_aggregator = Services::TeamMetricsAggregator.new(@parser, @selected_teams, cutoff_date)
      aggregated = team_aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')

      weekly_aggregator = WeeklyDataAggregator.new(cutoff_date)
      weekly_aggregator.aggregate_pair(
        aggregated[:created],
        aggregated[:completed],
        labels: %i[created completed]
      )
    end

    def build_transition_data
      TransitionDataBuilder.new(@metrics_by_category['transition_to'], cutoff_date, teams: @selected_teams).build
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
      ReportGenerator::STATE_CATEGORIES.each_with_object({}) do |(cat, states), lookup|
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

      ReportGenerator::STATE_CATEGORIES.each_key do |state|
        raw_val = week_totals[state]
        pct = total.positive? ? ((raw_val.to_f / total) * 100).round(1) : 0
        datasets[state][:percentages] << pct
        datasets[state][:raw] << raw_val
      end
    end
  end
end
