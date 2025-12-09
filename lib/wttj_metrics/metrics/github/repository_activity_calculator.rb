# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      class RepositoryActivityCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def to_rows
          # Group by date and repo
          grouped = @pull_requests.group_by do |pr|
            date = pr['createdAt'] || pr[:createdAt]
            date = Date.parse(date.to_s).to_s
            repo = extract_repo_name(pr)
            [date, repo]
          end

          grouped.map do |(date, repo), prs|
            [
              date,
              'github_repo_activity',
              repo,
              prs.count
            ]
          end
        end

        private

        def extract_repo_name(pull_request)
          name = pull_request.dig('repository', 'name') || pull_request.dig(:repository, :name)
          return name if name

          url = pull_request['url'] || pull_request[:url]
          return 'unknown' unless url

          # Extract from URL like https://github.com/organization/repo-name/pull/123
          match = url.match(%r{github\.com/[^/]+/([^/]+)})
          match ? match[1] : 'unknown'
        end
      end
    end
  end
end
