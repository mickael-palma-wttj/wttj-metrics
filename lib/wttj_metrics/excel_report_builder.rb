# frozen_string_literal: true

require 'axlsx'

module WttjMetrics
  # Builds Excel reports from metrics data
  # Single Responsibility: Excel file generation
  class ExcelReportBuilder
    METRIC_DESCRIPTIONS = {
      'avg_cycle_time_days' => 'Average time from work start to completion',
      'avg_lead_time_days' => 'Average time from creation to completion',
      'weekly_throughput' => 'Issues completed in last 7 days',
      'current_wip' => 'Work In Progress count',
      'current_cycle_velocity' => 'Story points completed in current cycle',
      'cycle_commitment_accuracy' => 'Planned work completed vs total planned',
      'cycle_carryover_count' => 'Issues carried over from previous cycles',
      'completion_rate' => 'Percentage of issues completed',
      'avg_blocked_time_hours' => 'Average time issues are blocked',
      'avg_backlog_age_days' => 'Average age of backlog items',
      'total_bugs' => 'Total bugs in workspace',
      'open_bugs' => 'Bugs not yet completed',
      'closed_bugs' => 'Bugs completed or canceled',
      'bugs_created_last_30d' => 'New bugs in last 30 days',
      'bugs_closed_last_30d' => 'Bugs resolved in last 30 days',
      'avg_bug_resolution_days' => 'Average time to resolve a bug',
      'bug_ratio' => 'Percentage of issues that are bugs'
    }.freeze

    def initialize(report_data)
      @data = report_data
      @package = Axlsx::Package.new
      @workbook = @package.workbook
      @header_style = create_header_style
    end

    def build(output_path)
      add_key_metrics_sheet
      add_bug_tracking_sheet
      add_distribution_sheet
      add_team_comparison_sheet
      add_cycles_sheet
      add_ticket_flow_sheet
      add_raw_data_sheet

      @package.serialize(output_path)
    end

    private

    def create_header_style
      @workbook.styles.add_style(
        bg_color: '2D3748',
        fg_color: 'FFFFFF',
        b: true,
        alignment: { horizontal: :center },
        border: { style: :thin, color: '4A5568' }
      )
    end

    def add_key_metrics_sheet
      @workbook.add_worksheet(name: 'Key Metrics') do |sheet|
        add_title_row(sheet, "Linear Metrics Report - #{@data[:today]}", columns: 3)
        sheet.add_row %w[Metric Value Description], style: @header_style

        add_metrics_rows(sheet, @data[:flow_metrics], :flow)
        add_metrics_rows(sheet, @data[:cycle_metrics], :cycle)
        add_metrics_rows(sheet, @data[:team_metrics], :team)

        sheet.column_widths 35, 15, 45
      end
    end

    def add_bug_tracking_sheet
      @workbook.add_worksheet(name: 'Bug Tracking') do |sheet|
        add_title_row(sheet, 'Bug Tracking Overview', columns: 3)
        sheet.add_row %w[Metric Value Description], style: @header_style

        @data[:bug_metrics].each do |m|
          sheet.add_row format_bug_metric_row(m)
        end

        sheet.add_row []
        sheet.add_row ['Bugs by Priority'], style: @header_style
        sheet.add_row %w[Priority Count], style: @header_style

        sorted_bugs = @data[:bugs_by_priority].sort_by do |m|
          %w[Urgent High Medium Low].index(m[:metric]) || 99
        end
        sorted_bugs.each { |m| sheet.add_row [m[:metric], m[:value].to_i] }

        sheet.column_widths 35, 15, 45
      end
    end

    def add_distribution_sheet
      @workbook.add_worksheet(name: 'Distribution') do |sheet|
        add_title_row(sheet, 'Current Distribution', columns: 2)

        add_section(sheet, 'Status Distribution', %w[Status Count]) do
          @data[:status_chart_data].map { |d| [d[:label], d[:value]] }
        end

        add_section(sheet, 'Priority Distribution', %w[Priority Count]) do
          @data[:priority_dist]
            .sort_by { |m| %w[Urgent High Medium Low].index(m[:metric]) || 99 }
            .map { |m| [m[:metric], m[:value].to_i] }
        end

        add_section(sheet, 'Issue Type Distribution', %w[Type Count]) do
          @data[:type_dist].map { |m| [m[:metric], m[:value].to_i] }
        end

        add_section(sheet, 'Top Assignees (WIP)', ['Assignee', 'Active Issues']) do
          @data[:assignee_dist].map { |m| [m[:metric], m[:value].to_i] }
        end

        sheet.column_widths 30, 15
      end
    end

    def add_team_comparison_sheet
      @workbook.add_worksheet(name: 'Team Comparison') do |sheet|
        add_title_row(sheet, 'Team Comparison', columns: 5)
        headers = ['Team', 'Cycles (with data)', 'Avg Velocity (pts)',
                   'Avg Tickets/Cycle', 'Avg Completion Rate (%)']
        sheet.add_row headers, style: @header_style

        @data[:team_stats].each do |team, stats|
          sheet.add_row [
            team,
            "#{stats[:cycles_with_data]}/#{stats[:total_cycles]}",
            stats[:avg_velocity],
            stats[:avg_tickets_per_cycle],
            stats[:avg_completion_rate].round(1)
          ]
        end

        sheet.column_widths 20, 18, 18, 18, 22
      end
    end

    def add_cycles_sheet
      @workbook.add_worksheet(name: 'Cycles by Team') do |sheet|
        add_title_row(sheet, 'Cycles by Team', columns: 8)

        @data[:cycles_by_team].each do |team, cycles|
          sheet.add_row [team], style: @header_style
          headers = ['Cycle', 'Status', 'Progress (%)', 'Issues (Done/Total)',
                     'Velocity (pts)', 'Assignees', 'Tickets/Day', 'Carryover']
          sheet.add_row headers, style: @header_style

          cycles.each { |c| sheet.add_row format_cycle_row(c) }
          sheet.add_row []
        end

        sheet.column_widths 40, 12, 12, 18, 14, 12, 14, 12
      end
    end

    def add_ticket_flow_sheet
      @workbook.add_worksheet(name: 'Ticket Flow') do |sheet|
        add_title_row(sheet, "Ticket Flow (Last #{@data[:days_to_show]} Days)", columns: 3)
        sheet.add_row %w[Week Created Completed], style: @header_style

        flow = @data[:weekly_flow_data]
        flow[:labels].each_with_index do |week, i|
          sheet.add_row [week, flow[:created_raw][i], flow[:completed_raw][i]]
        end

        sheet.column_widths 15, 12, 12
      end
    end

    def add_raw_data_sheet
      @workbook.add_worksheet(name: 'Raw Data') do |sheet|
        add_title_row(sheet, 'Raw Metrics Data', columns: 4)
        sheet.add_row %w[Date Category Metric Value], style: @header_style

        @data[:raw_data].each do |row|
          sheet.add_row [row['date'], row['category'], row['metric'], row['value']]
        end

        sheet.column_widths 12, 20, 40, 30
      end
    end

    # Helper methods

    def add_title_row(sheet, title, columns:)
      sheet.add_row [title], style: @header_style
      sheet.merge_cells("A1:#{('A'.ord + columns - 1).chr}1")
      sheet.add_row []
    end

    def add_section(sheet, title, headers)
      sheet.add_row []
      sheet.add_row [title], style: @header_style
      sheet.add_row headers, style: @header_style
      yield.each { |row| sheet.add_row row }
    end

    def add_metrics_rows(sheet, metrics, type)
      metrics.each do |m|
        label = m[:metric].gsub('_', ' ').capitalize
        unit = determine_unit(m[:metric], type)
        sheet.add_row [label, "#{m[:value].round(1)}#{unit}", METRIC_DESCRIPTIONS[m[:metric]] || '']
      end
    end

    def determine_unit(metric, _type)
      return ' days' if metric.include?('days')
      return ' issues' if metric.include?('throughput')
      return '%' if metric.include?('accuracy') || metric.include?('rate')
      return 'h' if metric.include?('hours')

      ''
    end

    def format_bug_metric_row(metric)
      label = metric[:metric].gsub('_', ' ').gsub('bugs ', '').gsub('bug ', '').capitalize
      unit = case metric[:metric]
             when 'avg_bug_resolution_days' then ' days'
             when 'bug_ratio' then '%'
             else ''
             end
      value = if metric[:metric].include?('days') || metric[:metric].include?('ratio')
                metric[:value].round(1)
              else
                metric[:value].to_i
              end
      [label, "#{value}#{unit}", METRIC_DESCRIPTIONS[metric[:metric]] || '']
    end

    def format_cycle_row(cycle)
      [
        cycle[:name],
        cycle[:status],
        cycle[:progress]&.round(1) || 0,
        "#{cycle[:completed_issues] || 0}/#{cycle[:total_issues] || 0}",
        cycle[:velocity] || 0,
        cycle[:assignee_count] || 0,
        cycle[:tickets_per_day]&.round(2) || 0,
        cycle[:carryover] || 0
      ]
    end
  end
end
