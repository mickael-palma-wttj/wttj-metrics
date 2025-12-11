# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Linear
      # Builds transition data for state flow charts
      class TransitionDataBuilder
        def initialize(transition_metrics, cutoff_date, teams: nil)
          @transition_metrics = transition_metrics || []
          @cutoff_date = cutoff_date
          @teams = teams
          @state_to_category = build_state_lookup
        end

        def build
          transition_data = aggregate_transitions
          transition_weekly = group_by_week(transition_data)

          build_result(transition_weekly, transition_data)
        end

        private

        def build_state_lookup
          Reports::Linear::ReportGenerator::STATE_CATEGORIES.each_with_object({}) do |(cat, states), lookup|
            states.each { |s| lookup[s] = cat }
          end
        end

        def aggregate_transitions
          filtered_metrics = @transition_metrics.select { |m| m[:date] >= @cutoff_date }

          # Filter by teams if specified (metrics are in format "Team:State" or just "State")
          if @teams
            team_metrics = filtered_metrics.select do |m|
              metric = m[:metric]
              if metric.include?(':')
                team = metric.split(':').first
                @teams.include?(team)
              else
                false # Skip non-team-specific metrics when filtering
              end
            end

            # Extract just the state part from "Team:State"
            mapped_metrics = team_metrics.map do |m|
              state = m[:metric].split(':').last
              { date: m[:date], state: @state_to_category[state] || 'Other', value: m[:value].to_i }
            end

            mapped_metrics.group_by { |m| m[:date] }
                          .transform_values { |arr| aggregate_by_state(arr) }
          else
            # No team filter, use all non-team-specific metrics
            filtered_metrics
              .reject { |m| m[:metric].include?(':') }
              .map { |m| { date: m[:date], state: @state_to_category[m[:metric]] || 'Other', value: m[:value].to_i } }
              .group_by { |m| m[:date] }
              .transform_values { |arr| aggregate_by_state(arr) }
          end
        end

        def aggregate_by_state(arr)
          arr.group_by { |m| m[:state] }
             .transform_values { |v| v.sum { |x| x[:value] } }
        end

        def group_by_week(transition_data)
          transition_data.keys.sort.group_by { |d| Date.parse(d).strftime('%Y-W%W') }
        end

        def build_result(transition_weekly, transition_data)
          labels = []
          datasets = Hash.new { |h, k| h[k] = { percentages: [], raw: [] } }

          transition_weekly.sort.each do |week, dates|
            labels << format_week_label(week, dates)
            week_totals = calculate_week_totals(dates, transition_data)
            populate_datasets(datasets, week_totals)
          end

          { labels: labels, datasets: datasets }
        end

        def format_week_label(week, dates)
          Date.strptime("#{week}-1", '%Y-W%W-1').strftime('%b %d')
        rescue StandardError
          Date.parse(dates.first).strftime('%b %d')
        end

        def calculate_week_totals(dates, transition_data)
          totals = Hash.new(0)
          dates.each do |d|
            (transition_data[d] || {}).each { |state, val| totals[state] += val }
          end
          totals
        end

        def populate_datasets(datasets, week_totals)
          total = week_totals.values.sum

          Reports::Linear::ReportGenerator::STATE_CATEGORIES.each_key do |state|
            raw_val = week_totals[state]
            pct = total.positive? ? ((raw_val.to_f / total) * 100).round(1) : 0
            datasets[state][:percentages] << pct
            datasets[state][:raw] << raw_val
          end
        end
      end
    end
  end
end
