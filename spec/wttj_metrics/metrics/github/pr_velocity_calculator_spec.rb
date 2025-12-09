# frozen_string_literal: true

require 'spec_helper'
require 'wttj_metrics/metrics/github/pr_velocity_calculator'

RSpec.describe WttjMetrics::Metrics::Github::PrVelocityCalculator do
  subject(:calculator) { described_class.new(pull_requests) }

  let(:pull_requests) do
    [
      {
        state: 'MERGED',
        createdAt: '2025-01-01T10:00:00Z',
        mergedAt: '2025-01-02T10:00:00Z', # 1 day to merge
        reviews: {
          nodes: [
            { createdAt: '2025-01-01T12:00:00Z' } # 2 hours to first review
          ]
        }
      },
      {
        state: 'MERGED',
        createdAt: '2025-01-03T10:00:00Z',
        mergedAt: '2025-01-05T10:00:00Z', # 2 days to merge
        reviews: {
          nodes: [
            { createdAt: '2025-01-03T16:00:00Z' }, # 6 hours to first review
            { createdAt: '2025-01-04T10:00:00Z' }
          ]
        }
      },
      {
        state: 'OPEN',
        createdAt: '2025-01-06T10:00:00Z',
        reviews: {
          nodes: []
        }
      }
    ]
  end

  describe '#calculate' do
    it 'calculates average time to merge' do
      result = calculator.calculate
      # (1 + 2) / 2 = 1.5 days
      expect(result[:avg_time_to_merge_days]).to eq(1.5)
    end

    it 'calculates total merged PRs' do
      result = calculator.calculate
      expect(result[:total_merged]).to eq(2)
    end

    it 'calculates average time to first review' do
      result = calculator.calculate
      # PR 1: 2 hours = 2/24 = 0.0833 days
      # PR 2: 6 hours = 6/24 = 0.25 days
      # Avg: (0.0833 + 0.25) / 2 = 0.1666... -> 0.1667
      expect(result[:avg_time_to_first_review_days]).to eq(0.1667)
    end
  end
end
