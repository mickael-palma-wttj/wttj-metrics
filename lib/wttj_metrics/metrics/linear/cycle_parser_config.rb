# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      # Configuration for cycle metric parsing
      # Single Responsibility: Metric parsing configuration
      # :reek:TooManyConstants - Configuration module is expected to have multiple constants
      module CycleParserConfig
        # Default teams for cycle parsing
        DEFAULT_TEAMS = Reports::Linear::DataProvider::SELECTED_TEAMS

        # Expected number of parts when splitting metric keys
        METRIC_PARTS_COUNT = 3

        # Parser functions for different metric types
        INTEGER_PARSER = lambda(&:to_i)
        ROUNDED_FLOAT_PARSER = ->(v) { v.to_f.round }
        STRING_PARSER = ->(v) { v.to_s.strip }

        # Maps metric names to their parser functions
        METRIC_PARSERS = {
          'total_issues' => INTEGER_PARSER,
          'completed_issues' => INTEGER_PARSER,
          'bug_count' => INTEGER_PARSER,
          'velocity' => INTEGER_PARSER,
          'planned_points' => INTEGER_PARSER,
          'completion_rate' => ROUNDED_FLOAT_PARSER,
          'carryover' => INTEGER_PARSER,
          'progress' => ROUNDED_FLOAT_PARSER,
          'duration_days' => INTEGER_PARSER,
          'tickets_per_day' => ROUNDED_FLOAT_PARSER,
          'assignee_count' => INTEGER_PARSER,
          'status' => STRING_PARSER,
          'scope_change' => ROUNDED_FLOAT_PARSER,
          'initial_scope' => INTEGER_PARSER,
          'final_scope' => INTEGER_PARSER
        }.freeze
      end
    end
  end
end
