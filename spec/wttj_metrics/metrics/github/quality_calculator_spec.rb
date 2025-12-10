# frozen_string_literal: true

require 'spec_helper'
require 'wttj_metrics/metrics/github/quality_calculator'

RSpec.describe WttjMetrics::Metrics::Github::QualityCalculator do
  subject(:calculator) { described_class.new(pull_requests, releases) }

  let(:pull_requests) { [] }
  let(:releases) { [] }

  describe '#calculate' do
    context 'with no data' do
      it 'returns zero values' do
        expect(calculator.calculate).to eq(
          ci_success_rate: 0.0,
          deploy_frequency_weekly: 0.0,
          deploy_frequency_daily: 0.0,
          hotfix_rate: 0.0,
          time_to_green_hours: 0.0
        )
      end
    end

    context 'with data' do
      let(:pull_requests) do
        [
          { state: 'MERGED', lastCommit: { nodes: [{ commit: { statusCheckRollup: { state: 'SUCCESS' } } }] } },
          { state: 'MERGED', lastCommit: { nodes: [{ commit: { statusCheckRollup: { state: 'FAILURE' } } }] } },
          { state: 'CLOSED' }
        ]
      end

      let(:releases) do
        [
          { 'created_at' => (Date.today - 14).to_s },
          { 'created_at' => (Date.today - 7).to_s },
          { 'created_at' => Date.today.to_s }
        ]
      end

      it 'calculates ci_success_rate' do
        # 2 merged PRs, 1 success, 1 failure -> 50%
        expect(calculator.calculate[:ci_success_rate]).to eq(50.0)
      end

      it 'calculates deploy_frequency_weekly' do
        # 3 releases over 14 days (2 weeks) -> 1.5/week
        expect(calculator.calculate[:deploy_frequency_weekly]).to eq(1.5)
      end

      it 'calculates deploy_frequency_daily' do
        # 3 releases over 14 days -> 0.21/day
        expect(calculator.calculate[:deploy_frequency_daily]).to be_within(0.01).of(0.21)
      end
    end

    context 'with time to green data' do
      let(:pull_requests) do
        [
          {
            state: 'MERGED',
            createdAt: '2025-01-01T10:00:00Z',
            lastCommit: {
              nodes: [
                {
                  commit: {
                    committedDate: '2025-01-01T11:00:00Z',
                    checkSuites: {
                      nodes: [
                        { conclusion: 'SUCCESS', updatedAt: '2025-01-01T11:30:00Z' } # 30 mins
                      ]
                    }
                  }
                }
              ]
            }
          }
        ]
      end

      it 'calculates time_to_green_hours' do
        expect(calculator.calculate[:time_to_green_hours]).to eq(0.5)
      end
    end
  end
end
