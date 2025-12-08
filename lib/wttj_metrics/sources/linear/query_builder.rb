# frozen_string_literal: true

module WttjMetrics
  module Sources
    module Linear
      # Builds GraphQL queries for Linear API
      class QueryBuilder
        ISSUES_PAGE_SIZE = 100
        HISTORY_PAGE_SIZE = 50
        USERS_PAGE_SIZE = 100
        WORKFLOW_STATES_PAGE_SIZE = 100
        CYCLES_PAGE_SIZE = 25

        class << self
          def issues(states: nil)
            filter_clause = build_filter_clause(states)

            <<~GRAPHQL
              query($after: String) {
                issues(first: #{ISSUES_PAGE_SIZE}, after: $after#{filter_clause}) {
                  #{page_info_fragment}
                  nodes {
                    #{issue_fields_fragment}
                  }
                }
              }
            GRAPHQL
          end

          def cycles
            <<~GRAPHQL
              query($after: String) {
                cycles(first: #{CYCLES_PAGE_SIZE}, after: $after, orderBy: createdAt) {
                  #{page_info_fragment}
                  nodes {
                    #{cycle_fields_fragment}
                  }
                }
              }
            GRAPHQL
          end

          def team_members
            <<~GRAPHQL
              query {
                users(first: #{USERS_PAGE_SIZE}) {
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

          def workflow_states
            <<~GRAPHQL
              query {
                workflowStates(first: #{WORKFLOW_STATES_PAGE_SIZE}) {
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

          private

          def build_filter_clause(states)
            return '' unless states

            filter = "state: { name: { in: #{states.to_json} } }"
            ", filter: { #{filter} }"
          end

          def page_info_fragment
            <<~GRAPHQL.strip
              pageInfo {
                hasNextPage
                endCursor
              }
            GRAPHQL
          end

          def issue_fields_fragment
            <<~GRAPHQL.strip
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
            GRAPHQL
          end

          def cycle_fields_fragment
            <<~GRAPHQL.strip
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
            GRAPHQL
          end
        end
      end
    end
  end
end
