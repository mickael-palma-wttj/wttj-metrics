# frozen_string_literal: true

module WttjMetrics
  # Transforms raw metrics into chart-ready data structures
  # Single Responsibility: Chart data preparation
  class ChartDataBuilder
    STATUS_GROUPS = {
      'Backlog' => %w[Backlog Triage Archived],
      'To Do' => ['Todo', 'To Do', 'To do', 'To design', 'To dev', 'To Qualify'],
      'In Progress' => ['In Progress', 'In progress'],
      'In Review' => ['In Review', 'To Review', 'To test', 'To Validate', 'To Merge (main)'],
      'Done' => %w[Done Released Canceled Duplicate Auto-closed]
    }.freeze

    PRIORITY_ORDER = %w[Urgent High Medium Low].freeze

    def initialize(metrics_parser)
      @parser = metrics_parser
    end

    def status_chart_data
      grouped = STATUS_GROUPS.map do |group_name, statuses|
        breakdown = build_breakdown(statuses)
        { label: group_name, value: breakdown.sum { |b| b[:count] }, breakdown: breakdown }
      end

      grouped
        .reject { |d| d[:value].zero? }
        .sort_by { |d| status_sort_order(d[:label]) }
    end

    def priority_chart_data
      @parser.metrics_for('priority').map do |m|
        { label: m[:metric], value: m[:value].to_i }
      end
    end

    def type_chart_data
      @parser.metrics_for('type').map do |m|
        { label: m[:metric], value: m[:value].to_i }
      end
    end

    def assignee_chart_data
      @parser.metrics_for('assignee')
             .sort_by { |m| -m[:value] }
             .first(15)
             .map { |m| { label: m[:metric], value: m[:value].to_i } }
    end

    private

    def build_breakdown(statuses)
      @parser.metrics_for('status')
             .select { |m| statuses.include?(m[:metric]) }
             .map { |m| { name: m[:metric], count: m[:value].to_i } }
             .reject { |b| b[:count].zero? }
             .sort_by { |b| -b[:count] }
    end

    def status_sort_order(label)
      ['Backlog', 'To Do', 'In Progress', 'In Review', 'Done'].index(label) || 99
    end
  end
end
