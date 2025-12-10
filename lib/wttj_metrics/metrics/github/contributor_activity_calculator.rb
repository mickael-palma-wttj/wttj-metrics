# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      class ContributorActivityCalculator
        def initialize(pull_requests)
          @pull_requests = pull_requests
        end

        def to_rows
          # Group by date and author
          grouped = @pull_requests.group_by do |pr|
            date = pr['createdAt'] || pr[:createdAt]
            date = Date.parse(date.to_s).to_s
            author = extract_author_login(pr)
            [date, author]
          end

          grouped.map do |(date, author), prs|
            [
              date,
              'github_contributor_activity',
              author,
              prs.count
            ]
          end
        end

        private

        def extract_author_login(pull_request)
          login = pull_request.dig('author', 'login') || pull_request.dig(:author, :login)
          login || 'unknown'
        end
      end
    end
  end
end
