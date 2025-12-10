# frozen_string_literal: true

require 'octokit'
require 'faraday'
require 'ruby-progressbar'
require 'date'

module WttjMetrics
  module Sources
    module Github
      class Client
        MAX_RETRIES = 3
        BASE_DELAY = 2

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
                  latestReviews(first: 10) {
                    nodes {
                      createdAt
                      state
                      author {
                        login
                      }
                    }
                  }
                  lastCommit: commits(last: 1) {
                    nodes {
                      commit {
                        committedDate
                        statusCheckRollup {
                          state
                        }
                        checkSuites(first: 10) {
                          nodes {
                            conclusion
                            updatedAt
                          }
                        }
                      }
                    }
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
                    latestReviews(first: 10) {
                      nodes {
                        createdAt
                        state
                        author {
                          login
                        }
                      }
                    }
                    lastCommit: commits(last: 1) {
                      nodes {
                        commit {
                          committedDate
                          statusCheckRollup {
                            state
                          }
                          checkSuites(first: 10) {
                            nodes {
                              conclusion
                              updatedAt
                            }
                          }
                        }
                      }
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
            response = with_retries do
              @client.post '/graphql', { query: query, variables: variables }.to_json
            end
            data = response.data.repository.pullRequests
            all_nodes.concat(data.nodes)

            break unless data.pageInfo.hasNextPage

            variables[:after] = data.pageInfo.endCursor
          end

          all_nodes.map(&:to_h)
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

        def fetch_releases(repo, from_date)
          repo.split('/')
          # Use REST API for releases as it's simpler for this use case
          # and we don't need complex graph traversal
          releases = with_retries do
            @client.releases(repo, per_page: 100)
          end

          releases.select { |r| r.created_at >= Date.parse(from_date).to_time }
                  .map(&:to_h)
        rescue Octokit::NotFound
          []
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

          progress_bar = if @logger
                           ProgressBar.create(
                             title: 'Fetching',
                             total: total_count,
                             format: '%t: |%B| %p%% %e'
                           )
                         end

          while has_next
            response = execute_search_query(search_query, cursor)
            data = response.data.search
            results.concat(data.nodes)
            cursor = data.pageInfo.endCursor
            has_next = data.pageInfo.hasNextPage
            if progress_bar
              new_progress = progress_bar.progress + data.nodes.size
              progress_bar.progress = [new_progress, progress_bar.total].min
            end
          end
          progress_bar&.finish

          results.map(&:to_h)
        end

        def get_issue_count(query_string)
          variables = { query: query_string }
          response = with_retries do
            @client.post '/graphql', { query: COUNT_QUERY, variables: variables }.to_json
          end
          handle_graphql_errors(response)
          response.data.search.issueCount
        end

        def execute_search_query(query_string, after_cursor)
          variables = { query: query_string, after: after_cursor }
          response = with_retries do
            @client.post '/graphql', { query: SEARCH_QUERY, variables: variables }.to_json
          end
          handle_graphql_errors(response)
          response
        end

        def handle_graphql_errors(response)
          if response[:errors]
            error_msg = response[:errors].map { |e| e[:message] }.join(', ')
            @logger&.error "❌ GraphQL Error: #{error_msg}"
            raise "GraphQL Error: #{error_msg}"
          end

          return unless response.data.nil?

          @logger&.error '❌ GraphQL Error: No data returned'
          raise 'GraphQL Error: No data returned'
        end

        def with_retries
          retries = MAX_RETRIES
          begin
            yield
          rescue Octokit::TooManyRequests => e
            sleep_time = e.response_headers['retry-after'].to_i
            sleep_time = 60 if sleep_time.zero?
            @logger&.warn "Rate limit exceeded. Retrying in #{sleep_time} seconds..."
            sleep sleep_time
            retry
          rescue Octokit::Unauthorized => e
            @logger&.error "❌ Authentication failed: #{e.message}. Please check your GITHUB_TOKEN."
            raise
          rescue Octokit::BadGateway, Octokit::ServiceUnavailable, Faraday::ConnectionFailed,
                 Faraday::TimeoutError => e
            if retries.positive?
              sleep_time = BASE_DELAY * (2**(MAX_RETRIES - retries))
              @logger&.warn "Error: #{e.class}. Retrying in #{sleep_time} seconds... (#{retries} retries left)"
              sleep sleep_time
              retries -= 1
              retry
            else
              @logger&.error "Failed after retries: #{e.message}"
              raise
            end
          end
        end
      end
    end
  end
end
