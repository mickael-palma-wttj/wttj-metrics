# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Reports
    module Linear
      class DataProvider
        SELECTED_TEAMS = ['ATS', 'Global ATS', 'Marketplace', 'Platform', 'ROI', 'Sourcing', 'Talents'].freeze

        attr_reader :data, :metrics_by_category, :days_to_show, :today, :selected_teams, :parser, :all_teams_mode

        def initialize(csv_path, days: 90, teams: nil)
          @csv_path = csv_path
          @days_to_show = days
          @today = Date.today.to_s
          @parser = Data::CsvParser.new(csv_path)
          @data = @parser.data
          @metrics_by_category = @parser.metrics_by_category

          @all_teams_mode = teams == :all
          @selected_teams = if @all_teams_mode
                              discover_all_teams
                            else
                              teams || SELECTED_TEAMS
                            end
        end

        def metrics_for(category)
          @parser.metrics_for(category)
        end

        def cutoff_date
          @cutoff_date ||= (Date.today - @days_to_show).to_s
        end

        private

        def discover_all_teams
          teams = Set.new
          @parser.metrics_for('bugs_by_team').each do |m|
            team = m[:metric].split(':').first
            teams << team if team && team != 'Unknown'
          end
          teams.to_a.sort
        end
      end
    end
  end
end
