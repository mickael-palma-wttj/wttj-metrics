# frozen_string_literal: true

require 'date'

module WttjMetrics
  # Facade that orchestrates all metric calculators
  # Delegates to specialized calculators for each metric category
  class MetricsCalculator
    def initialize(issues, cycles, team_members = [], workflow_states = [])
      @issues = issues
      @cycles = cycles
      @team_members = team_members
      @workflow_states = workflow_states
      @today = Date.today
    end

    # Returns an array of rows, each row is [date, category, metric_name, value]
    def calculate_all
      [
        flow_calculator.to_rows,
        cycle_calculator.to_rows,
        distribution_calculator.backlog_rows,
        team_calculator.to_rows,
        bug_calculator.to_rows,
        distribution_calculator.to_rows,
        timeseries_collector.to_rows
      ].flatten(1)
    end

    private

    attr_reader :issues, :cycles, :team_members, :workflow_states, :today

    def flow_calculator
      @flow_calculator ||= Metrics::FlowCalculator.new(issues, today: today)
    end

    def cycle_calculator
      @cycle_calculator ||= Metrics::CycleCalculator.new(cycles, today: today)
    end

    def bug_calculator
      @bug_calculator ||= Metrics::BugCalculator.new(issues, today: today)
    end

    def team_calculator
      @team_calculator ||= Metrics::TeamCalculator.new(issues, today: today)
    end

    def distribution_calculator
      @distribution_calculator ||= Metrics::DistributionCalculator.new(issues, today: today)
    end

    def timeseries_collector
      @timeseries_collector ||= Metrics::TimeseriesCollector.new(issues, today: today)
    end
  end
end
