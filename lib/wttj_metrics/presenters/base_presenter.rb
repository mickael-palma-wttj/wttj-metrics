# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Base presenter class with common formatting helpers
    class BasePresenter
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
        name.gsub('_', ' ').strip.capitalize
      end

      def tooltip
        ''
      end

      def unit
        ''
      end

      def display_value
        "#{value}#{unit}"
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
