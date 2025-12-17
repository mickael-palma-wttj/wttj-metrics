# frozen_string_literal: true

RSpec.describe WttjMetrics::Reports::Linear::PercentileDataBuilder do
  subject(:builder) { described_class.new(parser, teams: teams, cutoff_date: cutoff_date) }

  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:teams) { [] }
  let(:cutoff_date) { '2025-01-01' }

  let(:timeseries_metrics) do
    [
      { date: '2025-01-15', metric: 'tickets_created', value: '10' },
      { date: '2025-01-16', metric: 'tickets_created', value: '15' },
      { date: '2025-01-17', metric: 'tickets_created', value: '8' },
      { date: '2025-01-18', metric: 'tickets_created', value: '20' },
      { date: '2025-01-15', metric: 'tickets_completed', value: '8' },
      { date: '2025-01-16', metric: 'tickets_completed', value: '12' },
      { date: '2025-01-17', metric: 'tickets_completed', value: '5' },
      { date: '2025-01-18', metric: 'tickets_completed', value: '18' }
    ]
  end

  let(:bugs_by_team_metrics) do
    [
      { metric: 'TeamA:mttr', value: '5.5' },
      { metric: 'TeamA:created', value: '10' },
      { metric: 'TeamB:mttr', value: '8.2' },
      { metric: 'TeamB:created', value: '15' }
    ]
  end

  let(:cycle_metrics) do
    [
      { date: '2025-01-10', metric: 'TeamA:Cycle1:velocity', value: '20' },
      { date: '2025-01-10', metric: 'TeamA:Cycle1:progress', value: '85' },
      { date: '2025-01-17', metric: 'TeamA:Cycle2:velocity', value: '25' },
      { date: '2025-01-17', metric: 'TeamA:Cycle2:progress', value: '90' },
      { date: '2025-01-10', metric: 'TeamB:Cycle1:velocity', value: '15' },
      { date: '2025-01-10', metric: 'TeamB:Cycle1:progress', value: '70' }
    ]
  end

  describe '#throughput_percentiles' do
    before do
      allow(parser).to receive(:metrics_by_category).and_return({ 'timeseries' => timeseries_metrics })
    end

    it 'returns percentile data structure' do
      # Exercise
      result = builder.throughput_percentiles

      # Verify
      aggregate_failures do
        expect(result).to have_key(:created)
        expect(result).to have_key(:completed)
        expect(result).to have_key(:labels)
        expect(result[:labels]).to eq(%w[P50 P75 P90 P95])
      end
    end

    it 'calculates percentiles for created tickets' do
      result = builder.throughput_percentiles

      # With values [8, 10, 15, 20], P50 should be around 12.5
      expect(result[:created]).to be_an(Array)
      expect(result[:created].size).to eq(4)
      expect(result[:created].first).to be > 0
    end

    it 'calculates percentiles for completed tickets' do
      result = builder.throughput_percentiles

      expect(result[:completed]).to be_an(Array)
      expect(result[:completed].size).to eq(4)
    end
  end

  describe '#weekly_throughput_data' do
    before do
      allow(parser).to receive(:metrics_by_category).and_return({ 'timeseries' => timeseries_metrics })
    end

    it 'returns weekly aggregated data' do
      result = builder.weekly_throughput_data

      aggregate_failures do
        expect(result).to have_key(:labels)
        expect(result).to have_key(:created)
        expect(result).to have_key(:completed)
        expect(result).to have_key(:percentiles)
      end
    end

    it 'formats week labels correctly' do
      result = builder.weekly_throughput_data

      # Week labels should be in format WXX
      expect(result[:labels].first).to match(/^W\d+$/)
    end
  end

  describe '#bug_mttr_by_team' do
    before do
      allow(parser).to receive(:metrics_for).with('bugs_by_team').and_return(bugs_by_team_metrics)
    end

    it 'returns MTTR data grouped by team' do
      result = builder.bug_mttr_by_team

      aggregate_failures do
        expect(result).to have_key(:labels)
        expect(result).to have_key(:datasets)
        expect(result[:labels]).to include('TeamA', 'TeamB')
      end
    end

    it 'includes average MTTR value per team' do
      result = builder.bug_mttr_by_team

      team_a_data = result[:datasets].find { |d| d[:label] == 'TeamA' }
      expect(team_a_data[:value]).to eq(5.5)
    end

    context 'when filtering by teams' do
      let(:teams) { ['TeamA'] }

      it 'only includes specified teams' do
        result = builder.bug_mttr_by_team

        expect(result[:labels]).to eq(['TeamA'])
        expect(result[:labels]).not_to include('TeamB')
      end
    end
  end

  describe '#cycle_velocity_distribution' do
    before do
      allow(parser).to receive(:metrics_by_category).and_return({ 'cycle' => cycle_metrics })
    end

    it 'returns velocity percentile distribution' do
      result = builder.cycle_velocity_distribution

      aggregate_failures do
        expect(result).to have_key(:percentiles)
        expect(result).to have_key(:labels)
        expect(result).to have_key(:stats)
        expect(result[:percentiles].size).to eq(4)
      end
    end

    it 'calculates basic stats' do
      result = builder.cycle_velocity_distribution

      aggregate_failures do
        expect(result[:stats][:min]).to eq(15.0)
        expect(result[:stats][:max]).to eq(25.0)
        expect(result[:stats][:count]).to eq(3)
      end
    end
  end

  describe '#completion_rate_distribution' do
    before do
      allow(parser).to receive(:metrics_by_category).and_return({ 'cycle' => cycle_metrics })
    end

    it 'returns completion rate percentiles' do
      result = builder.completion_rate_distribution

      aggregate_failures do
        expect(result).to have_key(:percentiles)
        expect(result).to have_key(:distribution)
        expect(result).to have_key(:stats)
      end
    end

    it 'builds a histogram of completion rates' do
      result = builder.completion_rate_distribution

      expect(result[:distribution]).to be_an(Array)
      expect(result[:distribution].first).to have_key(:range)
      expect(result[:distribution].first).to have_key(:count)
    end
  end

  describe '#all_percentile_data' do
    before do
      allow(parser).to receive_messages(metrics_by_category: { 'timeseries' => [] }, metrics_for: [])
    end

    it 'returns combined percentile data for all metrics' do
      result = builder.all_percentile_data

      aggregate_failures do
        expect(result).to have_key(:throughput)
        expect(result).to have_key(:weekly_throughput)
        expect(result).to have_key(:bug_mttr)
        expect(result).to have_key(:velocity)
        expect(result).to have_key(:completion)
      end
    end
  end

  describe 'edge cases' do
    context 'with empty data' do
      before do
        allow(parser).to receive_messages(metrics_by_category: { 'timeseries' => [] }, metrics_for: [])
      end

      it 'handles empty timeseries gracefully' do
        result = builder.throughput_percentiles

        expect(result[:created]).to eq([0, 0, 0, 0])
        expect(result[:completed]).to eq([0, 0, 0, 0])
      end

      it 'handles empty velocity data gracefully' do
        result = builder.cycle_velocity_distribution

        aggregate_failures do
          expect(result[:stats][:count]).to eq(0)
          expect(result[:stats][:avg]).to eq(0)
        end
      end
    end

    context 'with cutoff date filtering' do
      let(:cutoff_date) { '2025-01-17' }

      before do
        allow(parser).to receive(:metrics_by_category).and_return({ 'timeseries' => timeseries_metrics })
      end

      it 'filters out data before cutoff date' do
        result = builder.throughput_percentiles

        # Should only include dates >= 2025-01-17
        # Created: [8, 20], Completed: [5, 18]
        expect(result[:created].first).to be_between(8, 20)
      end
    end
  end
end
