# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      # Base class for Linear metric calculators
      class Base < Metrics::Base
        include Helpers::Linear::IssueHelper

        private

        def completed_issues
          @completed_issues ||= issues.select { |i| issue_completed?(i) }
        end
      end
    end
  end
end
