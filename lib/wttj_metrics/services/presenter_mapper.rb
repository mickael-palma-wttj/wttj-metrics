# frozen_string_literal: true

module WttjMetrics
  module Services
    # Service object for mapping metrics to presenter objects
    # Single Responsibility: Presenter instantiation
    class PresenterMapper
      def self.map_to_presenters(metrics, presenter_class)
        return [] if metrics.nil? || metrics.empty?

        metrics.map { |metric| presenter_class.new(metric) }
      end

      def self.map_hash_to_presenters(hash, presenter_class)
        return {} if hash.nil? || hash.empty?

        hash.transform_values do |items|
          Array(items).map { |item| presenter_class.new(item) }
        end
      end

      def self.map_team_stats_to_presenters(hash, presenter_class)
        return [] if hash.nil? || hash.empty?

        hash.map { |team, stats| presenter_class.new(team, stats) }
      end
    end
  end
end
