# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      class Calculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate_all
          [
            pr_velocity_calculator.to_rows,
            collaboration_calculator.to_rows,
            timeseries_calculator.to_rows,
            pr_size_calculator.to_rows,
            repository_activity_calculator.to_rows
          ].flatten(1)
        end

        private

        attr_reader :pull_requests

        def repository_activity_calculator
          @repository_activity_calculator ||= RepositoryActivityCalculator.new(pull_requests)
        end

        def pr_velocity_calculator
          @pr_velocity_calculator ||= PrVelocityCalculator.new(pull_requests)
        end

        def collaboration_calculator
          @collaboration_calculator ||= CollaborationCalculator.new(pull_requests)
        end

        def timeseries_calculator
          @timeseries_calculator ||= TimeseriesCalculator.new(pull_requests)
        end

        def pr_size_calculator
          @pr_size_calculator ||= PrSizeCalculator.new(pull_requests)
        end
      end
    end
  end
end
