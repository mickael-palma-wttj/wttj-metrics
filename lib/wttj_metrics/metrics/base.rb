# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Base class for all metric calculators
    # Provides common functionality and interface
    class Base
      def initialize(issues, today: Date.today)
        @issues = issues
        @today = today
      end

      # Template method - subclasses must implement
      def calculate
        raise NotImplementedError, "#{self.class} must implement #calculate"
      end

      private

      attr_reader :issues, :today

      def completed_issues
        @completed_issues ||= issues.select { |i| i['completedAt'] }
      end

      def issue_is_bug?(issue)
        labels = (issue.dig('labels', 'nodes') || []).map { |l| l['name'].downcase }
        labels.any? { |l| l.include?('bug') || l.include?('fix') }
      end

      def parse_date(date_string)
        Date.parse(date_string) if date_string
      end

      def parse_datetime(date_string)
        DateTime.parse(date_string) if date_string
      end
    end
  end
end
