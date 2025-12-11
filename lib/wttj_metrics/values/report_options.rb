# frozen_string_literal: true

module WttjMetrics
  module Values
    # Value object for report command options
    class ReportOptions
      attr_reader :output, :days, :teams, :excel_enabled, :excel_path, :teams_config

      def initialize(options_hash)
        @output = options_hash[:output]
        @days = options_hash[:days]
        @teams = determine_teams(options_hash)
        @excel_enabled = options_hash[:excel]
        @excel_path = options_hash[:excel_path]
        @teams_config = options_hash[:teams_config]
      end

      private

      def determine_teams(options_hash)
        options_hash[:all_teams] ? :all : options_hash[:teams]
      end
    end
  end
end
