# frozen_string_literal: true

require 'erb'
require 'date'
require 'json'
require 'forwardable'

module WttjMetrics
  module Reports
    module Linear
      # Generates HTML and Excel reports from CSV metrics data
      # Facade pattern: Coordinates multiple specialized classes
      # :reek:TooManyMethods
      class ReportGenerator
        extend Forwardable

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

        def initialize(csv_path, days: 90, teams: nil, teams_config: nil)
          @data_provider = DataProvider.new(csv_path, days: days, teams: teams, teams_config: teams_config)
        end

        def generate_html(output_path)
          html = build_html
          File.write(output_path, html)
          puts "✅ HTML report generated: #{output_path}"
        end

        def generate_excel(output_path)
          builder = ExcelReportBuilder.new(excel_report_data)
          builder.build(output_path)
          puts "✅ Excel report generated: #{output_path}"
        end

        # Delegations to DataProvider
        def_delegators :@data_provider, :data, :metrics_by_category, :days_to_show, :today,
                       :selected_teams, :all_teams_mode, :parser, :cutoff_date, :team_mapping_display

        # Raw metrics accessors (delegated to DataProvider)
        def_delegator :@data_provider, :metrics_for

        def flow_metrics = metrics_for('flow')
        def cycle_metrics = metrics_for('cycle_metrics')
        def team_metrics = metrics_for('team')
        def bug_metrics = metrics_for('bugs')

        # Metric accessors with presenters
        def flow_metrics_presented
          presented_metrics('flow', Presenters::FlowMetricPresenter)
        end

        def cycle_metrics_presented
          presented_metrics('cycle_metrics', Presenters::CycleMetricPresenter)
        end

        def team_metrics_presented
          presented_metrics('team', Presenters::TeamMetricPresenter)
        end

        def bug_metrics_presented
          presented_metrics('bugs', Presenters::BugMetricPresenter)
        end

        def bugs_by_team_presented
          @bugs_by_team_presented ||= bugs_by_team.map { |team, stats| Presenters::BugTeamPresenter.new(team, stats) }
        end

        def bugs_by_priority
          @bugs_by_priority ||= @data_provider.metrics_for('bugs_by_priority')
        end

        def bugs_by_team
          @bugs_by_team ||= build_bugs_by_team
        end

        def status_dist
          @status_dist ||= @data_provider.metrics_for('status')
        end

        def priority_dist
          @priority_dist ||= @data_provider.metrics_for('priority')
        end

        def type_dist
          @type_dist ||= @data_provider.metrics_for('type')
        end

        def assignee_dist
          @assignee_dist ||= @data_provider.metrics_for('assignee')
                                           .sort_by { |m| -m[:value] }
                                           .first(15)
        end

        def weekly_flow_data
          @weekly_flow_data ||= weekly_flow_builder.build_flow_data
        end

        def weekly_bug_flow_data
          @weekly_bug_flow_data ||= weekly_flow_builder.build_bug_flow_data
        end

        def weekly_bug_flow_by_team_data
          @weekly_bug_flow_by_team_data ||= weekly_flow_builder.build_bug_flow_by_team_data(
            weekly_bug_flow_data[:labels]
          )
        end

        def transition_weekly_data
          @transition_weekly_data ||= TransitionDataBuilder.new(
            metrics_by_category['transition_to'],
            cutoff_date,
            teams: selected_teams
          ).build
        end

        def status_chart_data
          @status_chart_data ||= ChartDataBuilder.new(parser).status_chart_data
        end

        def priority_chart_data
          priority_dist.map { |m| { label: m[:metric], value: m[:value].to_i } }
        end

        def type_chart_data
          type_dist.map do |m|
            {
              label: m[:metric],
              value: m[:value].to_i,
              breakdown: type_breakdown_for(m[:metric])
            }
          end
        end

        def ticket_activity
          @ticket_activity ||= begin
            data = metrics_for('linear_ticket_activity')

            # Initialize 7x24 grid with zeros
            activity = Array.new(7) { Array.new(24, 0) }

            data.each do |row|
              # metric is "wday_hour" (e.g. "1_14")
              wday, hour = row[:metric].split('_').map(&:to_i)
              # Adjust wday to match JS array (0=Mon, 6=Sun)
              # Ruby wday: 0=Sun, 1=Mon...
              display_wday = (wday - 1) % 7
              activity[display_wday][hour] = row[:value].to_i
            end

            activity
          end
        end

        def assignee_chart_data
          assignee_dist.map { |m| { label: m[:metric], value: m[:value].to_i } }
        end

        def cycles_parsed
          filtered_cycles = metrics_by_category['cycle']&.select { |m| m[:date] >= cutoff_date } || []
          @cycles_parsed ||= Metrics::Linear::CycleParser.new(
            filtered_cycles,
            teams: selected_teams,
            teams_config: nil,
            available_teams: @data_provider.available_teams
          ).parse
        end

        def cycles_by_team
          filtered_cycles = metrics_by_category['cycle']&.select { |m| m[:date] >= cutoff_date } || []
          @cycles_by_team ||= Metrics::Linear::CycleParser.new(
            filtered_cycles,
            teams: selected_teams,
            teams_config: nil,
            available_teams: @data_provider.available_teams
          ).by_team
        end

        def cycles_by_team_presented
          @cycles_by_team_presented ||= cycles_by_team.transform_values do |cycles|
            cycles.map { |c| Presenters::CyclePresenter.new(c) }
          end
        end

        def team_stats
          @team_stats ||= Metrics::Linear::TeamStatsCalculator.new(cycles_by_team).calculate
        end

        private

        def presented_metrics(category, presenter_class)
          @presented_metrics ||= {}
          @presented_metrics[category] ||= @data_provider.metrics_for(category).map { |m| presenter_class.new(m) }
        end

        def weekly_flow_builder
          @weekly_flow_builder ||= WeeklyFlowBuilder.new(
            parser,
            selected_teams,
            cutoff_date,
            teams_config: nil,
            available_teams: @data_provider.available_teams
          )
        end

        def build_bugs_by_team
          BugsByTeamBuilder.new(@data_provider, selected_teams).build
        end

        def type_breakdown_for(type)
          metric = type_breakdown.find { |m| m[:metric] == type }
          return {} unless metric

          JSON.parse(metric[:value])
        rescue JSON::ParserError
          {}
        end

        def type_breakdown
          @type_breakdown ||= @data_provider.metrics_for('type_breakdown')
        end

        def state_to_category
          @state_to_category ||= STATE_CATEGORIES.each_with_object({}) do |(cat, states), lookup|
            states.each { |s| lookup[s] = cat }
          end
        end

        def build_html
          template_path = File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'linear_report.html.erb')

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
            <head><title>Linear Metrics - #{today}</title></head>
            <body>
              <h1>Linear Metrics Dashboard</h1>
              <p>Generated: #{today}</p>
              <p>Please run with the proper template file.</p>
            </body>
            </html>
          HTML
        end

        def excel_report_data
          {
            today: today,
            days_to_show: days_to_show,
            flow_metrics: @data_provider.metrics_for('flow'),
            cycle_metrics: @data_provider.metrics_for('cycle_metrics'),
            team_metrics: @data_provider.metrics_for('team'),
            bug_metrics: @data_provider.metrics_for('bugs'),
            bugs_by_priority: bugs_by_priority,
            status_chart_data: status_chart_data,
            priority_dist: priority_dist,
            type_dist: type_dist,
            assignee_dist: assignee_dist,
            team_stats: team_stats,
            cycles_by_team: cycles_by_team,
            weekly_flow_data: weekly_flow_data,
            raw_data: data
          }
        end
      end
    end
  end
end
