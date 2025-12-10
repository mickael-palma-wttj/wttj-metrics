# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      class RepositoryActivityCalculator
        CATEGORY = 'github_repo_activity'

        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def calculate
          @pull_requests.each_with_object(Hash.new(0)) do |pull_request, counts|
            key = [extract_date(pull_request), extract_repo_name(pull_request)]
            counts[key] += 1
          end
        end

        def to_rows
          calculate.map do |(date, repo), count|
            [date, CATEGORY, repo, count]
          end
        end

        private

        def extract_date(pull_request)
          date_str = pull_request[:createdAt] || pull_request['createdAt']
          Date.parse(date_str.to_s).to_s
        end

        def extract_repo_name(pull_request)
          name = pull_request.dig(:repository, :name) || pull_request.dig('repository', 'name')
          return name if name

          parse_repo_from_url(pull_request[:url] || pull_request['url'])
        end

        def parse_repo_from_url(url)
          return 'unknown' unless url

          url.match(%r{github\.com/[^/]+/([^/]+)})&.captures&.first || 'unknown'
        end
      end
    end
  end
end
