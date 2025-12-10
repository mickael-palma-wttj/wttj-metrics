# frozen_string_literal: true

module WttjMetrics
  module Metrics
    module Github
      module Timeseries
        class ReleaseMetrics
          def initialize
            @releases_count = 0
            @hotfix_count = 0
          end

          def record(release)
            @releases_count += 1
            name = release['name'] || release[:name] || ''
            tag = release['tag_name'] || release[:tag_name] || ''
            @hotfix_count += 1 if name.downcase.include?('hotfix') || tag.downcase.include?('hotfix')
          end

          def record_from_pr(pull_request)
            title = pull_request['title'] || pull_request[:title] || ''
            state = pull_request['state'] || pull_request[:state]

            return unless state == 'MERGED'

            @hotfix_count += 1 if title.downcase.include?('hotfix')
          end

          def metrics
            {
              releases_count: @releases_count,
              hotfix_count: @hotfix_count,
              hotfix_rate: rate(@hotfix_count, @releases_count),
              deploy_frequency_daily: @releases_count
            }
          end

          private

          def rate(numerator, denominator)
            return 0.0 unless denominator&.positive?

            ((numerator.to_f / denominator) * 100).round(2)
          end
        end
      end
    end
  end
end
