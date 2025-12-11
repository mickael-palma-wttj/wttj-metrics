# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      class Calculator
        def initialize(pull_requests, releases = [], teams = {})
          @pull_requests = pull_requests
          @releases = releases || []
          @teams = teams || {}
        end

        def calculate_all
          global_metrics = calculate_metrics_set(@pull_requests, 'github')

          team_metrics = @teams.flat_map do |team_name, members|
            team_prs = @pull_requests.select do |pr|
              members.include?(pr.dig(:author, :login))
            end
            calculate_metrics_set(team_prs, "github:#{team_name}")
          end

          global_metrics + team_metrics
        end

        private

        attr_reader :pull_requests, :releases

        def calculate_metrics_set(prs, category)
          ts_category = category == 'github' ? 'github_daily' : "#{category}_daily"

          [
            PrVelocityCalculator.new(prs).to_rows(category),
            CollaborationCalculator.new(prs).to_rows(category),
            TimeseriesCalculator.new(prs, releases).to_rows(ts_category),
            PrSizeCalculator.new(prs).to_rows(category),
            RepositoryActivityCalculator.new(prs).to_rows(category),
            ContributorActivityCalculator.new(prs).to_rows(category),
            QualityCalculator.new(prs, releases).to_rows(category),
            CommitActivityCalculator.new(prs).to_rows(category)
          ].flatten(1)
        end
      end
    end
  end
end
