# frozen_string_literal: true

module WttjMetrics
  module Metrics
    # Collects timeseries data for issues and transitions
    class TimeseriesCollector < Base
      COMPLETED_STATES = %w[completed canceled].freeze

      def to_rows
        collect_data
        build_rows
      end

      private

      def collect_data
        reset_counters
        process_issues
      end

      def reset_counters
        @created_per_day = Hash.new(0)
        @completed_per_day = Hash.new(0)
        @bugs_created_per_day = Hash.new(0)
        @bugs_closed_per_day = Hash.new(0)
        @bugs_by_team = Hash.new { |h, k| h[k] = { created: 0, closed: 0, open: 0 } }
        @tickets_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
        @completed_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
        @bugs_created_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
        @bugs_closed_by_team = Hash.new { |h, k| h[k] = Hash.new(0) }
        @transitions = Hash.new { |h, k| h[k] = Hash.new(0) }
        @transitions_by_team = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = Hash.new(0) } }
      end

      def process_issues
        issues.each { |issue| process_issue(issue) }
      end

      def process_issue(issue)
        team = issue.dig('team', 'name') || 'Unknown'
        is_bug = issue_is_bug?(issue)

        process_creation(issue, team, is_bug)
        process_completion(issue, team, is_bug)
        process_bug_stats(issue, team) if is_bug
        process_transitions(issue, team)
      end

      def process_creation(issue, team, is_bug)
        return unless issue['createdAt']

        date = parse_date(issue['createdAt']).to_s
        @created_per_day[date] += 1
        @tickets_by_team[date][team] += 1

        return unless is_bug

        @bugs_created_per_day[date] += 1
        @bugs_created_by_team[date][team] += 1
      end

      def process_completion(issue, team, is_bug)
        return unless issue['completedAt']

        date = parse_date(issue['completedAt']).to_s
        @completed_per_day[date] += 1
        @completed_by_team[date][team] += 1

        return unless is_bug

        @bugs_closed_per_day[date] += 1
        @bugs_closed_by_team[date][team] += 1
      end

      def process_bug_stats(issue, team)
        @bugs_by_team[team][:created] += 1

        if COMPLETED_STATES.include?(issue.dig('state', 'type'))
          @bugs_by_team[team][:closed] += 1

          # Calculate resolution time for MTTR
          if issue['completedAt']
            created = parse_date(issue['createdAt'])
            completed = parse_date(issue['completedAt'])
            resolution_days = (completed - created).to_f
            @bugs_by_team[team][:resolution_times] ||= []
            @bugs_by_team[team][:resolution_times] << resolution_days
          end
        else
          @bugs_by_team[team][:open] += 1
        end
      end

      def process_transitions(issue, team)
        history = issue.dig('history', 'nodes') || []

        history.each do |event|
          next unless event['toState']

          date = parse_date(event['createdAt']).to_s
          state = event.dig('toState', 'name')

          next unless state

          @transitions[date][state] += 1
          @transitions_by_team[date][team][state] += 1
        end
      end

      def build_rows
        rows = []
        rows.concat(ticket_rows)
        rows.concat(bug_rows)
        rows.concat(transition_rows)
        rows
      end

      def ticket_rows
        rows = @created_per_day.map { |date, count| [date, 'timeseries', 'tickets_created', count] }
        @completed_per_day.each { |date, count| rows << [date, 'timeseries', 'tickets_completed', count] }

        @tickets_by_team.each do |date, teams|
          teams.each { |team, count| rows << [date, 'timeseries', "tickets_created_#{team}", count] }
        end

        @completed_by_team.each do |date, teams|
          teams.each { |team, count| rows << [date, 'timeseries', "tickets_completed_#{team}", count] }
        end

        rows
      end

      def bug_rows
        rows = @bugs_created_per_day.map { |date, count| [date, 'timeseries', 'bugs_created', count] }
        @bugs_closed_per_day.each { |date, count| rows << [date, 'timeseries', 'bugs_closed', count] }

        @bugs_by_team.each do |team, stats|
          rows << [today.to_s, 'bugs_by_team', "#{team}:created", stats[:created]]
          rows << [today.to_s, 'bugs_by_team', "#{team}:closed", stats[:closed]]
          rows << [today.to_s, 'bugs_by_team', "#{team}:open", stats[:open]]

          # Calculate MTTR (Mean Time To Resolve)
          resolution_times = stats[:resolution_times] || []
          mttr = resolution_times.empty? ? 0 : (resolution_times.sum / resolution_times.size).round(1)
          rows << [today.to_s, 'bugs_by_team', "#{team}:mttr", mttr]
        end

        @bugs_created_by_team.each do |date, teams|
          teams.each { |team, count| rows << [date, 'timeseries', "bugs_created_#{team}", count] }
        end

        @bugs_closed_by_team.each do |date, teams|
          teams.each { |team, count| rows << [date, 'timeseries', "bugs_closed_#{team}", count] }
        end

        rows
      end

      def transition_rows
        rows = []

        @transitions.each do |date, states|
          states.each { |state, count| rows << [date, 'transition_to', state, count] }
        end

        @transitions_by_team.each do |date, teams|
          teams.each do |team, states|
            states.each { |state, count| rows << [date, 'transition_to', "#{team}:#{state}", count] }
          end
        end

        rows
      end
    end
  end
end
