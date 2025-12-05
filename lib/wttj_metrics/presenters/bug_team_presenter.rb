# frozen_string_literal: true

module WttjMetrics
  module Presenters
    # Presenter for bug flow by team table rows
    class BugTeamPresenter
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

        ((closed.to_f / created) * 100).round(1)
      end

      def resolution_rate_display
        "#{resolution_rate}%"
      end

      def resolution_rate_class
        if resolution_rate >= 80
          'status-active'
        elsif resolution_rate >= 50
          'status-upcoming'
        else
          'status-past'
        end
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
