# frozen_string_literal: true

require 'octokit'
require 'date'

module WttjMetrics
  module Sources
    module Github
      class Client
        SEARCH_QUERY = <<~GRAPHQL
          query($query: String!, $after: String) {
            search(query: $query, type: ISSUE, first: 25, after: $after) {
              issueCount
              nodes {
                ... on PullRequest {
                  url
                  createdAt
                  updatedAt
                  mergedAt
                  closedAt
                  state
                  title
                  additions
                  deletions
                  changedFiles
                  commits(first: 1) {
                    totalCount
                  }
                  author {
                    login
                  }
                  reviews(first: 50) {
                    totalCount
                    nodes {
                      createdAt
                      state
                      author {
                        login
                      }
                      body
                    }
                  }
                  comments(first: 50) {
                    totalCount
                    nodes {
                      createdAt
                      author {
                        login
                      }
                      body
                    }
                  }
                  repository {
                    name
                  }
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        GRAPHQL

        COUNT_QUERY = <<~GRAPHQL
          query($query: String!) {
            search(query: $query, type: ISSUE, first: 1) {
              issueCount
            }
          }
        GRAPHQL

        def initialize(logger: nil)
          @client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN', nil))
          @logger = logger
        end

        def fetch_pull_requests(repo, from_date)
          query = <<~GRAPHQL
            query($repoOwner: String!, $repoName: String!, $fromDate: DateTime!, $after: String) {
              repository(owner: $repoOwner, name: $repoName) {
                pullRequests(first: 25, orderBy: {field: CREATED_AT, direction: DESC}, after: $after) {
                  nodes {
                    createdAt
                    mergedAt
                    closedAt
                    state
                    title
                    additions
                    deletions
                    changedFiles
                    commits(first: 1) {
                      totalCount
                    }
                    author {
                      login
                    }
                    reviews(first: 50) {
                      totalCount
                      nodes {
                        createdAt
                        state
                        author {
                          login
                        }
                        body
                      }
                    }
                    comments(first: 50) {
                      totalCount
                      nodes {
                        createdAt
                        author {
                          login
                        }
                        body
                      }
                    }
                  }
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                }
              }
            }
          GRAPHQL

          owner, name = repo.split('/')
          variables = { repoOwner: owner, repoName: name, fromDate: from_date, after: nil }

          all_nodes = []
          loop do
            response = @client.post '/graphql', { query: query, variables: variables }.to_json
            data = response.data.repository.pullRequests
            all_nodes.concat(data.nodes)

            break unless data.pageInfo.hasNextPage

            variables[:after] = data.pageInfo.endCursor
          end

          all_nodes
        end

        def fetch_organization_pull_requests(org, from_date)
          start_date = Date.parse(from_date)
          end_date = Date.today

          fetch_recursive(org, start_date, end_date)
        end

        def fetch_organization_pull_requests_updated_after(org, from_date)
          start_date = Date.parse(from_date)
          end_date = Date.today

          fetch_recursive(org, start_date, end_date, date_field: 'updated')
        end

        private

        def fetch_recursive(org, start_date, end_date, date_field: 'created')
          search_query = "org:#{org} is:pr #{date_field}:#{start_date.iso8601}..#{end_date.iso8601}"

          total_count = get_issue_count(search_query)

          if total_count > 1000
            mid_date = start_date + ((end_date - start_date).to_i / 2)

            # Ensure we have at least 2 days to split
            if mid_date < end_date
              @logger&.info "   Splitting date range: #{start_date}..#{end_date} (#{total_count} PRs)"
              return fetch_recursive(org, start_date, mid_date, date_field: date_field) +
                     fetch_recursive(org, mid_date + 1, end_date, date_field: date_field)
            end
          end

          @logger&.info "   Fetching #{total_count} PRs for #{start_date}..#{end_date} (#{date_field})"

          # If count <= 1000 or we can't split further, fetch the data
          results = []
          cursor = nil
          has_next = true

          while has_next
            response = execute_search_query(search_query, cursor)
            data = response.data.search
            results.concat(data.nodes)
            cursor = data.pageInfo.endCursor
            has_next = data.pageInfo.hasNextPage
            print '.' if @logger # Simple progress indicator
          end
          puts '' if @logger # Newline after dots

          results.map(&:to_h)
        end

        def get_issue_count(query_string)
          variables = { query: query_string }
          response = @client.post '/graphql', { query: COUNT_QUERY, variables: variables }.to_json
          response.data.search.issueCount
        end

        def execute_search_query(query_string, after_cursor)
          variables = { query: query_string, after: after_cursor }
          @client.post '/graphql', { query: SEARCH_QUERY, variables: variables }.to_json
        end
      end
    end
  end
end
