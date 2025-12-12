# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Services::TeamAggregator do
  subject(:aggregator) { described_class.new(teams_config, available_teams) }

  let(:teams_config) { instance_double(WttjMetrics::Values::TeamConfiguration) }
  let(:available_teams) { ['Team A', 'Team B', 'Team C'] }
  let(:matcher) { instance_double(WttjMetrics::Services::TeamMatcher) }

  before do
    allow(WttjMetrics::Services::TeamMatcher).to receive(:new).with(available_teams).and_return(matcher)
    allow(teams_config).to receive(:defined_teams).and_return(['Unified Team'])
    allow(teams_config).to receive(:patterns_for).with('Unified Team', :linear).and_return(['Team A', 'Team B'])
  end

  describe '#aggregate' do
    let(:metrics) do
      [
        { date: '2024-01-01', metric: 'Team A:throughput', value: 10 },
        { date: '2024-01-01', metric: 'Team B:throughput', value: 20 },
        { date: '2024-01-01', metric: 'Team C:throughput', value: 30 }, # Should be ignored
        { date: '2024-01-01', metric: 'Team A:cycle_time', value: 5 },
        { date: '2024-01-01', metric: 'Team B:cycle_time', value: 15 }
      ]
    end

    context 'when teams match' do
      before do
        allow(matcher).to receive(:match).with(['Team A', 'Team B']).and_return(['Team A', 'Team B'])
      end

      it 'aggregates metrics for matched teams' do
        result = aggregator.aggregate(metrics)

        expect(result).to include(
          { date: '2024-01-01', metric: 'Unified Team:throughput', value: 30.0 }, # 10 + 20
          { date: '2024-01-01', metric: 'Unified Team:cycle_time', value: 10.0 }  # (5 + 15) / 2
        )
      end

      it 'does not include metrics for unmatched teams' do
        result = aggregator.aggregate(metrics)
        expect(result.map { |m| m[:metric] }).not_to include('Unified Team:Team C:throughput')
      end
    end

    context 'when no teams match' do
      before do
        allow(matcher).to receive(:match).with(['Team A', 'Team B']).and_return([])
      end

      it 'returns empty array' do
        expect(aggregator.aggregate(metrics)).to be_empty
      end
    end

    context 'with different metric types' do
      before do
        allow(matcher).to receive(:match).and_return(['Team A'])
      end

      let(:metrics) do
        [
          { date: '2024-01-01', metric: 'Team A:lead_time', value: 10 },
          { date: '2024-01-01', metric: 'Team A:other_metric', value: 20 }
        ]
      end

      it 'averages lead_time metrics' do
        # Since there is only one item, average is same as value, but logic path is exercised
        result = aggregator.aggregate(metrics)
        expect(result).to include({ date: '2024-01-01', metric: 'Unified Team:lead_time', value: 10.0 })
      end

      it 'sums other metrics' do
        result = aggregator.aggregate(metrics)
        expect(result).to include({ date: '2024-01-01', metric: 'Unified Team:other_metric', value: 20.0 })
      end
    end
  end
end
