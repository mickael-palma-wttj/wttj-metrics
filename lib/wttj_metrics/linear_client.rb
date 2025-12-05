# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module WttjMetrics
  # Client for Linear GraphQL API
  class LinearClient
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
      cache_key = 'issues_all'

      cached(cache_key) do
        issues = []
        cursor = nil

        loop do
          result = query(issues_query(states), { after: cursor })
          data = result.dig('data', 'issues')

          issues.concat(data['nodes'])

          break unless data.dig('pageInfo', 'hasNextPage')

          cursor = data.dig('pageInfo', 'endCursor')
        end

        issues
      end
    end

    def fetch_cycles
      cached('cycles_all') do
        result = query(cycles_query)
        result.dig('data', 'cycles', 'nodes') || []
      end
    end

    def fetch_team_members
      cached('team_members_all') do
        result = query(team_members_query)
        result.dig('data', 'users', 'nodes') || []
      end
    end

    def fetch_workflow_states
      cached('workflow_states_all') do
        result = query(workflow_states_query)
        result.dig('data', 'workflowStates', 'nodes') || []
      end
    end

    private

    def cached(key, &)
      return yield unless @cache

      @cache.fetch(key, &)
    end

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
              history(first: 50) {
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
        query {
          cycles(first: 100, orderBy: createdAt) {
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
