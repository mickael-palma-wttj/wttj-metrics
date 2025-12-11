# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Metrics
    module Github
      class ContributorActivityCalculator
        METRIC_NAME = 'github_contributor_activity'

        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          @pull_requests.each_with_object(Hash.new(0)) do |pr, counts|
            counts[group_key(pr)] += 1
          end
        end

        def to_rows(category = nil)
          cat = category ? "#{category}_contributor_activity" : METRIC_NAME
          calculate.map do |(date, author), count|
            [date, cat, author, count]
          end
        end

        private

        def group_key(pull_request)
          [extract_date(pull_request), extract_author(pull_request)]
        end

        def extract_date(pull_request)
          date_str = pull_request[:createdAt] || pull_request['createdAt']
          Date.parse(date_str.to_s).to_s
        end

        def extract_author(pull_request)
          pull_request.dig(:author, :login) || pull_request.dig('author', 'login') || 'unknown'
        end
      end
    end
  end
end
