# frozen_string_literal: true

require 'yaml'

module WttjMetrics
  module Values
    class TeamConfiguration
      attr_reader :teams

      def initialize(config_path)
        @config_path = config_path
        @teams = load_config
      end

      def defined_teams
        @teams.keys
      end

      def patterns_for(team_name, source)
        patterns = @teams.dig(team_name, source.to_s)
        return [] unless patterns

        Array(patterns)
      end

      private

      def load_config
        return {} unless File.exist?(@config_path)

        config = YAML.load_file(@config_path)
        config['teams'] || {}
      end
    end
  end
end
