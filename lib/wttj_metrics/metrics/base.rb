# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Base class for all metric calculators
    # Provides common functionality and interface
    class Base
      include Helpers::DateHelper
      include Helpers::IssueHelper

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
        @completed_issues ||= issues.select { |i| issue_completed?(i) }
      end
    end
  end
end
