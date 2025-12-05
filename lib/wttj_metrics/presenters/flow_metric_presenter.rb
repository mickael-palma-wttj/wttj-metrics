# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for flow metrics (cycle time, lead time, throughput, WIP)
    class FlowMetricPresenter < BasePresenter
      TOOLTIPS = {
        'avg_cycle_time_days' => "Average time from when work starts on an issue until it's completed.",
        'avg_lead_time_days' => 'Average time from issue creation to completion.',
        'weekly_throughput' => 'Number of issues completed in the last 7 days.',
        'current_wip' => 'Work In Progress: issues currently being worked on.'
      }.freeze

      def label
        name.gsub('_', ' ')
            .gsub('avg ', 'Avg ')
            .gsub('days', '')
            .gsub('current ', '')
            .strip
            .capitalize
      end

      def tooltip
        TOOLTIPS[name] || ''
      end

      def unit
        return ' days' if name.include?('days')
        return ' issues' if name.include?('throughput') || name.include?('wip')

        ''
      end
    end
  end
end
