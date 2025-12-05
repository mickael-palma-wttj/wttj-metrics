# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Base presenter class with common formatting helpers
    class BasePresenter
      include Helpers::FormattingHelper

      def initialize(metric)
        @metric = metric
      end

      def name
        @metric[:metric]
      end

      def raw_value
        @metric[:value]
      end

      def value
        raw_value.to_i
      end

      def label
        humanize_metric_name(name)
      end

      def tooltip
        ''
      end

      def unit
        ''
      end

      def display_value
        format_with_unit(value, unit)
      end

      def to_h
        {
          label: label,
          value: value,
          display_value: display_value,
          tooltip: tooltip,
          unit: unit
        }
      end
    end
  end
end
