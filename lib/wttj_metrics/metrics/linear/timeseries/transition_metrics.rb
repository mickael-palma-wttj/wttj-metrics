# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Linear
      module Timeseries
        # Tracks state transition metrics per date
        class TransitionMetrics
          def initialize
            @transitions = Hash.new { |h, k| h[k] = Hash.new(0) }
            @transitions_by_team = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = Hash.new(0) } }
          end

          def record_transitions(date, issue)
            team = issue.dig('team', 'name') || 'Unknown'
            history = issue.dig('history', 'nodes') || []

            history.each do |event|
              record_transition(date, event, team)
            end
          end

          def to_rows
            rows = []

            @transitions.each do |date, states|
              states.each do |state, count|
                rows << [date, 'transition_to', state, count]
              end
            end

            @transitions_by_team.each do |date, teams|
              teams.each do |team, states|
                states.each do |state, count|
                  rows << [date, 'transition_to', "#{team}:#{state}", count]
                end
              end
            end

            rows
          end

          private

          def record_transition(date, event, team)
            return unless event['toState']

            state = event.dig('toState', 'name')
            return unless state

            @transitions[date][state] += 1
            @transitions_by_team[date][team][state] += 1
          end
        end
      end
    end
  end
end
