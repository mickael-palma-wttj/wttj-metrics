# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for bug flow by team table rows
    class BugTeamPresenter
      include Helpers::FormattingHelper

      EXCELLENT_RESOLUTION_RATE = 80
      GOOD_RESOLUTION_RATE = 50

      def initialize(team, stats)
        @team = team
        @stats = stats
      end

      def name
        @team
      end

      def created
        @stats[:created]
      end

      def closed
        @stats[:closed]
      end

      def open
        @stats[:open]
      end

      def resolution_rate
        return 0 unless created.positive?

        format_percentage(closed, created)
      end

      def resolution_rate_display
        format_with_unit(resolution_rate, '%')
      end

      def resolution_rate_class
        if resolution_rate >= EXCELLENT_RESOLUTION_RATE
          'status-active'
        elsif resolution_rate >= GOOD_RESOLUTION_RATE
          'status-upcoming'
        else
          'status-past'
        end
      end

      def mttr
        @stats[:mttr] || 0
      end

      def mttr_display
        return 'N/A' if mttr.zero?

        format_with_unit(mttr, 'd')
      end

      def to_h
        {
          name: name,
          created: created,
          closed: closed,
          open: open,
          resolution_rate: resolution_rate,
          resolution_rate_display: resolution_rate_display,
          resolution_rate_class: resolution_rate_class
        }
      end
    end
  end
end
