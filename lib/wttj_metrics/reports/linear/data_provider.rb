# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Linear
      class DataProvider
        attr_reader :data, :metrics_by_category, :days_to_show, :today, :selected_teams, :parser, :all_teams_mode,
                    :teams_config

        def initialize(csv_path, days: 90, teams: nil, teams_config: nil)
          @csv_path = csv_path
          @days_to_show = days
          @today = Date.today.to_s
          @parser = Data::CsvParser.new(csv_path)
          @data = @parser.data
          @metrics_by_category = @parser.metrics_by_category
          @teams_config = teams_config

          @all_teams_mode = teams == :all
          @selected_teams = if @teams_config
                              resolve_teams_from_config
                            elsif @all_teams_mode
                              discover_all_teams
                            else
                              teams || []
                            end
        end

        def metrics_for(category)
          @parser.metrics_for(category)
        end

        def cutoff_date
          @cutoff_date ||= (Date.today - @days_to_show).to_s
        end

        def team_mapping_display
          return selected_teams.map { |t| "• #{t}" }.join('<br>') unless @teams_config

          @teams_config.defined_teams.map do |unified_name|
            patterns = @teams_config.patterns_for(unified_name, :linear)
            "• #{unified_name} (#{patterns.join(', ')})"
          end.join('<br>')
        end

        def available_teams
          @available_teams ||= begin
            teams = Set.new
            # Scan multiple metric types to find all teams
            %w[bugs_by_team team cycle].each do |category|
              @parser.metrics_for(category).each do |m|
                next unless m[:metric].include?(':')

                team = m[:metric].split(':').first
                teams << team if team && team != 'Unknown'
              end
            end
            # puts "DEBUG: Available teams: #{teams.to_a.sort.join(', ')}"
            teams.to_a.sort
          end
        end

        private

        def aggregate_metrics(metrics)
          # Use the cached available_teams if possible, or derive from current metrics
          teams_in_metrics = metrics.map { |m| m[:metric].split(':').first }.uniq
          Services::TeamAggregator.new(@teams_config, teams_in_metrics).aggregate(metrics)
        end

        def discover_all_teams
          available_teams
        end

        def resolve_teams_from_config
          matcher = Services::TeamMatcher.new(available_teams)
          @teams_config.defined_teams.flat_map do |unified_name|
            patterns = @teams_config.patterns_for(unified_name, :linear)
            matcher.match(patterns)
          end.uniq.sort
        end
      end
    end
  end
end
