# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class PrActivityMetrics
          attr_reader :created, :merged, :closed, :open, :total_merge_time

          def initialize
            @created = 0
            @merged = 0
            @closed = 0
            @open = 0
            @total_merge_time = 0.0
          end

          def record(pull_request)
            @created += 1
            update_state(pull_request)
          end

          def metrics
            {
              created: @created,
              merged: @merged,
              closed: @closed,
              open: @open,
              avg_time_to_merge_hours: average_merge_time
            }
          end

          private

          def update_state(pull_request)
            state = pull_request[:state] || pull_request['state']
            case state
            when 'MERGED'
              handle_merged(pull_request)
            when 'CLOSED'
              @closed += 1
            when 'OPEN'
              @open += 1
            end
          end

          def handle_merged(pull_request)
            @merged += 1
            merged_at = pull_request[:mergedAt] || pull_request['mergedAt']
            created_at = pull_request[:createdAt] || pull_request['createdAt']
            return unless merged_at

            @total_merge_time += (Time.parse(merged_at) - Time.parse(created_at))
          end

          def average_merge_time
            return 0.0 if @merged.zero?

            (@total_merge_time.to_f / @merged / 3600.0).round(2)
          end
        end
      end
    end
  end
end
