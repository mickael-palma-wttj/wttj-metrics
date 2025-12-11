# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Linear::WeeklyBugFlowBuilder do
  subject(:builder) { described_class.new(parser, selected_teams, cutoff_date) }

  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:selected_teams) { %w[ATS Platform] }
  let(:cutoff_date) { '2024-01-01' }

  describe '#initialize' do
    it 'accepts parser, teams, and cutoff date' do
      expect { builder }.not_to raise_error
    end
  end

  describe '#build_flow_data' do
    let(:team_aggregator) { instance_double(WttjMetrics::Services::TeamMetricsAggregator) }
    let(:aggregated_data) do
      {
        created: [{ date: '2024-01-15', value: 5 }],
        completed: [{ date: '2024-01-15', value: 3 }]
      }
    end
    let(:weekly_result) do
      {
        labels: ['Jan 15'],
        created_raw: [5],
        closed_raw: [3],
        created_pct: [62.5],
        closed_pct: [37.5]
      }
    end

    before do
      allow(WttjMetrics::Services::TeamMetricsAggregator).to receive(:new)
        .with(parser, selected_teams, cutoff_date)
        .and_return(team_aggregator)
      allow(team_aggregator).to receive(:aggregate_timeseries)
        .with('bugs_created', 'bugs_closed')
        .and_return(aggregated_data)

      weekly_aggregator = instance_double(WttjMetrics::Reports::Linear::WeeklyDataAggregator)
      allow(WttjMetrics::Reports::Linear::WeeklyDataAggregator).to receive(:new)
        .with(cutoff_date)
        .and_return(weekly_aggregator)
      allow(weekly_aggregator).to receive(:aggregate_pair).and_return(weekly_result)
    end

    it 'returns remapped flow data' do
      result = builder.build_flow_data

      aggregate_failures do
        expect(result).to have_key(:labels)
        expect(result).to have_key(:created)
        expect(result).to have_key(:closed)
        expect(result).to have_key(:created_pct)
        expect(result).to have_key(:closed_pct)
      end
    end

    it 'maps created_raw to created' do
      result = builder.build_flow_data
      expect(result[:created]).to eq([5])
    end

    it 'maps closed_raw to closed' do
      result = builder.build_flow_data
      expect(result[:closed]).to eq([3])
    end
  end

  describe '#build_by_team_data' do
    let(:base_labels) { ['Jan 15', 'Jan 22'] }
    let(:ats_metrics) do
      [
        { date: '2024-01-15', value: 3 },
        { date: '2024-01-16', value: 2 }
      ]
    end
    let(:platform_metrics) do
      [
        { date: '2024-01-22', value: 4 }
      ]
    end

    before do
      allow(parser).to receive(:timeseries_for)
        .with('bugs_created_ATS', since: cutoff_date)
        .and_return(ats_metrics)
      allow(parser).to receive(:timeseries_for)
        .with('bugs_created_Platform', since: cutoff_date)
        .and_return(platform_metrics)
    end

    it 'returns hash with labels and teams' do
      result = builder.build_by_team_data(base_labels)

      aggregate_failures do
        expect(result[:labels]).to eq(base_labels)
        expect(result[:teams]).to have_key('ATS')
        expect(result[:teams]).to have_key('Platform')
      end
    end
  end
end
