# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Linear::WeeklyFlowBuilder do
  subject(:builder) { described_class.new(parser, teams, cutoff_date) }

  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:teams) { ['Team A'] }
  let(:cutoff_date) { Date.parse('2023-01-01') }
  let(:aggregator) { instance_double(WttjMetrics::Reports::Linear::WeeklyDataAggregator) }

  before do
    allow(WttjMetrics::Reports::Linear::WeeklyDataAggregator).to receive(:new).and_return(aggregator)
  end

  describe '#build_flow_data' do
    let(:created_data) { [{ date: '2023-01-02', value: 10 }] }
    let(:completed_data) { [{ date: '2023-01-02', value: 5 }] }
    let(:expected_result) do
      {
        labels: ['Jan 02'],
        created_pct: [100],
        completed_pct: [50],
        created_raw: [10],
        completed_raw: [5]
      }
    end

    before do
      allow(parser).to receive(:timeseries_for)
        .with('tickets_created_Team A', since: cutoff_date)
        .and_return(created_data)
      allow(parser).to receive(:timeseries_for)
        .with('tickets_completed_Team A', since: cutoff_date)
        .and_return(completed_data)
      allow(aggregator).to receive(:aggregate_pair).and_return(expected_result)
    end

    it 'delegates to aggregator with correct data' do
      expect(builder.build_flow_data).to eq(expected_result)
    end
  end

  describe '#build_bug_flow_data' do
    let(:created_data) { [{ date: '2023-01-02', value: 8 }] }
    let(:closed_data) { [{ date: '2023-01-02', value: 4 }] }
    let(:aggregator_result) do
      {
        labels: ['Jan 02'],
        created_pct: [100],
        closed_pct: [50],
        created_raw: [8],
        closed_raw: [4]
      }
    end
    let(:expected_result) do
      {
        labels: ['Jan 02'],
        created: [8],
        closed: [4],
        created_pct: [100],
        closed_pct: [50]
      }
    end

    before do
      allow(parser).to receive(:timeseries_for)
        .with('bugs_created_Team A', since: cutoff_date)
        .and_return(created_data)
      allow(parser).to receive(:timeseries_for)
        .with('bugs_closed_Team A', since: cutoff_date)
        .and_return(closed_data)
      allow(aggregator).to receive(:aggregate_pair).and_return(aggregator_result)
    end

    it 'formats bug flow data correctly' do
      expect(builder.build_bug_flow_data).to eq(expected_result)
    end
  end

  describe '#build_bug_flow_by_team_data' do
    let(:base_labels) { ['Jan 02'] }
    let(:created_data) { [{ date: '2023-01-02', value: 5 }] }

    before do
      allow(parser).to receive(:timeseries_for)
        .with('bugs_created_Team A', since: cutoff_date)
        .and_return(created_data)
    end

    it 'returns structured team data' do
      result = builder.build_bug_flow_by_team_data(base_labels)

      expect(result[:labels]).to eq(base_labels)
      expect(result[:teams]['Team A'][:created]).to eq([5])
      expect(result[:teams]['Team A'][:closed]).to eq([])
    end
  end
end
