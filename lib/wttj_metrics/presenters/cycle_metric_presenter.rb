# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for cycle metrics (velocity, commitment accuracy, carryover)
    class CycleMetricPresenter < BasePresenter
      TOOLTIPS = {
        'current_cycle_velocity' => 'Total story points completed in the current cycle.',
        'cycle_commitment_accuracy' => 'Average percentage of planned work completed across all completed cycles.',
        'cycle_carryover_count' => 'Average number of issues carried over per completed cycle.'
      }.freeze

      def label
        name.tr('_', ' ')
            .gsub('current ', '')
            .gsub('cycle ', '')
            .strip
            .capitalize
      end

      def tooltip
        TOOLTIPS[name] || ''
      end

      def unit
        name.include?('accuracy') ? '%' : ''
      end
    end
  end
end
