# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for cycle metrics (velocity, commitment accuracy, carryover)
    class CycleMetricPresenter < BasePresenter
      TOOLTIPS = {
        'current_cycle_velocity' => 'Total story points completed in the current cycle.',
        'cycle_commitment_accuracy' => 'Percentage of planned work completed vs total planned.',
        'cycle_carryover_count' => 'Number of issues carried over from previous cycles.'
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
