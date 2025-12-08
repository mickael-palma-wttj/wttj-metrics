# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module WttjMetrics
  module Sources
    module Linear
      # Client for Linear GraphQL API
      class Client
        def initialize(api_key = nil, cache: nil)
          @api_key = api_key || Config.linear_api_key
          @cache = cache
        end

        def query(graphql_query, variables = {})
          uri = URI.parse(Config.linear_api_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.request_uri)
          request['Content-Type'] = 'application/json'
          request['Authorization'] = @api_key
          request.body = { query: graphql_query, variables: variables }.to_json

          response = http.request(request)

          raise Error, "Linear API Error: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)
        end

        def fetch_all_issues(states: nil)
          cached('issues_all') do
            paginate(QueryBuilder.issues(states: states), 'issues')
          end
        end

        def fetch_cycles
          cached('cycles_all') do
            paginate(QueryBuilder.cycles, 'cycles')
          end
        end

        def fetch_team_members
          cached('team_members_all') do
            result = query(QueryBuilder.team_members)
            result.dig('data', 'users', 'nodes') || []
          end
        end

        def fetch_workflow_states
          cached('workflow_states_all') do
            result = query(QueryBuilder.workflow_states)
            result.dig('data', 'workflowStates', 'nodes') || []
          end
        end

        private

        def cached(key, &)
          return yield unless @cache

          @cache.fetch(key, &)
        end

        def paginate(graphql_query, resource_key)
          items = []
          cursor = nil

          loop do
            result = query(graphql_query, { after: cursor })
            data = result.dig('data', resource_key)

            items.concat(data['nodes'])

            break unless data.dig('pageInfo', 'hasNextPage')

            cursor = data.dig('pageInfo', 'endCursor')
          end

          items
        end

        # Deprecated - remove after transition complete
        def issues_query(states)
          filter = []
          filter << "state: { name: { in: #{states.to_json} } }" if states
          filter_str = filter.any? ? "filter: { #{filter.join(', ')} }" : ''

          <<~GRAPHQL
            query($after: String) {
              issues(first: 100, after: $after, #{filter_str}) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                nodes {
                  id
                  identifier
                  title
                  createdAt
                  updatedAt
                  completedAt
                  startedAt
                  canceledAt
                  estimate
                  priority
                  priorityLabel
                  state {
                    id
                    name
                    type
                  }
                  assignee {
                    id
                    name
                    email
                  }
                  team {
                    id
                    name
                  }
                  cycle {
                    id
                    name
                    startsAt
                    endsAt
                  }
                  labels {
                    nodes {
                      name
                    }
                  }
                  history(first: #{HISTORY_PAGE_SIZE}) {
                    nodes {
                      createdAt
                      fromState {
                        name
                        type
                      }
                      toState {
                        name
                        type
                      }
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        def cycles_query
          <<~GRAPHQL
            query($after: String) {
              cycles(first: 25, after: $after, orderBy: createdAt) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                nodes {
                  id
                  name
                  number
                  startsAt
                  endsAt
                  completedAt
                  progress
                  team {
                    id
                    name
                  }
                  scopeHistory
                  issues {
                    nodes {
                      id
                      identifier
                      estimate
                      completedAt
                      assignee {
                        id
                      }
                      state {
                        type
                      }
                    }
                  }
                  uncompletedIssuesUponClose {
                    nodes {
                      id
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        def team_members_query
          <<~GRAPHQL
            query {
              users(first: 100) {
                nodes {
                  id
                  name
                  email
                  active
                }
              }
            }
          GRAPHQL
        end

        def workflow_states_query
          <<~GRAPHQL
            query {
              workflowStates(first: 100) {
                nodes {
                  id
                  name
                  type
                  position
                }
              }
            }
          GRAPHQL
        end
      end
    end
  end
end
