# frozen_string_literal: true

RSpec.describe WttjMetrics::WeeklyDataAggregator do
  subject(:aggregator) { described_class.new(cutoff_date) }

  let(:cutoff_date) { Date.new(2024, 12, 1) }

  describe '#aggregate_single' do
    subject(:result) { aggregator.aggregate_single(metric_data) }

    context 'with data from multiple days in same week' do
      # Setup
      let(:metric_data) do
        [
          { date: '2024-12-02', value: 5 },  # Monday
          { date: '2024-12-03', value: 3 },  # Tuesday
          { date: '2024-12-04', value: 2 }   # Wednesday
        ]
      end

      it 'sums values and creates single week label', :aggregate_failures do
        # Exercise & Verify (subject is called implicitly)
        expect(result[:values]).to eq([10])
        expect(result[:labels]).to eq(['Dec 02'])
      end
    end

    context 'with data spanning multiple weeks' do
      # Setup
      let(:metric_data) do
        [
          { date: '2024-12-02', value: 5 },  # Week 1 - Monday
          { date: '2024-12-09', value: 3 }   # Week 2 - Monday
        ]
      end

      it 'creates separate entries for each week', :aggregate_failures do
        # Exercise & Verify
        expect(result[:labels]).to eq(['Dec 02', 'Dec 09'])
        expect(result[:values]).to eq([5, 3])
      end
    end

    context 'with empty data' do
      # Setup
      let(:metric_data) { [] }

      it 'returns empty arrays', :aggregate_failures do
        # Exercise & Verify
        expect(result[:labels]).to be_empty
        expect(result[:values]).to be_empty
      end
    end
  end

  describe '#aggregate_pair' do
    subject(:result) do
      aggregator.aggregate_pair(created_data, completed_data, labels: %i[created completed])
    end

    # Setup
    let(:created_data) do
      [
        { date: '2024-12-02', value: 10 },
        { date: '2024-12-09', value: 8 }
      ]
    end

    let(:completed_data) do
      [
        { date: '2024-12-02', value: 6 },
        { date: '2024-12-09', value: 12 }
      ]
    end

    it 'returns raw values for both metrics', :aggregate_failures do
      # Exercise & Verify
      expect(result[:created_raw]).to eq([10, 8])
      expect(result[:completed_raw]).to eq([6, 12])
    end

    it 'calculates percentages correctly', :aggregate_failures do
      # Exercise & Verify
      # Week 1: 10/(10+6) = 62.5%, 6/(10+6) = 37.5%
      expect(result[:created_pct].first).to eq(62.5)
      expect(result[:completed_pct].first).to eq(37.5)

      # Week 2: 8/(8+12) = 40%, 12/(8+12) = 60%
      expect(result[:created_pct].last).to eq(40.0)
      expect(result[:completed_pct].last).to eq(60.0)
    end

    context 'with only one metric having data' do
      subject(:result) do
        aggregator.aggregate_pair(single_metric, [], labels: %i[a b])
      end

      # Setup
      let(:single_metric) { [{ date: '2024-12-02', value: 5 }] }

      it 'handles missing data gracefully', :aggregate_failures do
        # Exercise & Verify
        expect(result[:a_raw]).to eq([5])
        expect(result[:b_raw]).to eq([0])
        expect(result[:a_pct]).to eq([100.0])
        expect(result[:b_pct]).to eq([0])
      end
    end
  end

  describe 'week boundary handling' do
    subject(:result) { aggregator.aggregate_single(metric_data) }

    context 'with dates at year boundary (Week 00 edge case)' do
      # Setup
      let(:metric_data) do
        [
          { date: '2024-12-30', value: 3 },  # Monday (last week of 2024)
          { date: '2025-01-02', value: 5 }   # Thursday (same week, spans year)
        ]
      end

      it 'groups dates in the same week together', :aggregate_failures do
        # Exercise & Verify
        expect(result[:labels].size).to eq(1)
        expect(result[:values]).to eq([8])
      end
    end

    context 'with Sunday dates' do
      # Setup
      let(:metric_data) do
        [
          { date: '2024-12-01', value: 2 },  # Sunday
          { date: '2024-12-02', value: 3 }   # Monday (next week)
        ]
      end

      it 'places Sunday in the previous week' do
        # Exercise & Verify
        expect(result[:labels].size).to eq(2)
      end
    end
  end
end
