# frozen_string_literal: true

RSpec.describe WttjMetrics::Services::TeamMetricsAggregator do
  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:teams) { %w[ATS Platform Sourcing] }
  let(:cutoff_date) { '2024-01-01' }
  let(:aggregator) { described_class.new(parser, teams, cutoff_date) }

  describe '#aggregate_timeseries' do
    let(:ats_created) do
      [
        { date: '2024-01-01', value: 5 },
        { date: '2024-01-02', value: 3 }
      ]
    end

    let(:platform_created) do
      [
        { date: '2024-01-01', value: 2 },
        { date: '2024-01-03', value: 4 }
      ]
    end

    let(:sourcing_created) do
      [
        { date: '2024-01-02', value: 1 }
      ]
    end

    let(:ats_completed) do
      [
        { date: '2024-01-01', value: 3 },
        { date: '2024-01-02', value: 2 }
      ]
    end

    let(:platform_completed) do
      [
        { date: '2024-01-01', value: 1 },
        { date: '2024-01-03', value: 3 }
      ]
    end

    let(:sourcing_completed) do
      [
        { date: '2024-01-02', value: 2 }
      ]
    end

    before do
      allow(parser).to receive(:timeseries_for).with('tickets_created_ATS', since: cutoff_date)
                                               .and_return(ats_created)
      allow(parser).to receive(:timeseries_for).with('tickets_created_Platform', since: cutoff_date)
                                               .and_return(platform_created)
      allow(parser).to receive(:timeseries_for).with('tickets_created_Sourcing', since: cutoff_date)
                                               .and_return(sourcing_created)

      allow(parser).to receive(:timeseries_for).with('tickets_completed_ATS', since: cutoff_date)
                                               .and_return(ats_completed)
      allow(parser).to receive(:timeseries_for).with('tickets_completed_Platform', since: cutoff_date)
                                               .and_return(platform_completed)
      allow(parser).to receive(:timeseries_for).with('tickets_completed_Sourcing', since: cutoff_date)
                                               .and_return(sourcing_completed)
    end

    it 'aggregates created metrics across all teams' do
      result = aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')

      expect(result[:created]).to eq([
                                       { date: '2024-01-01', value: 7 }, # ATS: 5 + Platform: 2
                                       { date: '2024-01-02', value: 4 },  # ATS: 3 + Sourcing: 1
                                       { date: '2024-01-03', value: 4 }   # Platform: 4
                                     ])
    end

    it 'aggregates completed metrics across all teams' do
      result = aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')

      expect(result[:completed]).to eq([
                                         { date: '2024-01-01', value: 4 }, # ATS: 3 + Platform: 1
                                         { date: '2024-01-02', value: 4 },  # ATS: 2 + Sourcing: 2
                                         { date: '2024-01-03', value: 3 }   # Platform: 3
                                       ])
    end

    it 'returns hash with created and completed keys' do
      result = aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')

      expect(result).to have_key(:created)
      expect(result).to have_key(:completed)
    end

    context 'when no data exists for a team' do
      before do
        allow(parser).to receive(:timeseries_for).with('tickets_created_Sourcing', since: cutoff_date)
                                                 .and_return([])
        allow(parser).to receive(:timeseries_for).with('tickets_completed_Sourcing', since: cutoff_date)
                                                 .and_return([])
      end

      it 'handles empty data gracefully' do
        result = aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')

        expect(result[:created]).to eq([
                                         { date: '2024-01-01', value: 7 },
                                         { date: '2024-01-02', value: 3 },
                                         { date: '2024-01-03', value: 4 }
                                       ])
      end
    end

    context 'with bug metrics' do
      let(:bugs_created) do
        [
          { date: '2024-01-01', value: 10 }
        ]
      end

      let(:bugs_closed) do
        [
          { date: '2024-01-01', value: 8 }
        ]
      end

      before do
        allow(parser).to receive(:timeseries_for).with('bugs_created_ATS', since: cutoff_date)
                                                 .and_return(bugs_created)
        allow(parser).to receive(:timeseries_for).with('bugs_closed_ATS', since: cutoff_date)
                                                 .and_return(bugs_closed)
        allow(parser).to receive(:timeseries_for).with('bugs_created_Platform', since: cutoff_date)
                                                 .and_return([])
        allow(parser).to receive(:timeseries_for).with('bugs_closed_Platform', since: cutoff_date)
                                                 .and_return([])
        allow(parser).to receive(:timeseries_for).with('bugs_created_Sourcing', since: cutoff_date)
                                                 .and_return([])
        allow(parser).to receive(:timeseries_for).with('bugs_closed_Sourcing', since: cutoff_date)
                                                 .and_return([])
      end

      it 'aggregates bug metrics correctly' do
        result = aggregator.aggregate_timeseries('bugs_created', 'bugs_closed')

        expect(result[:created]).to eq([{ date: '2024-01-01', value: 10 }])
        expect(result[:completed]).to eq([{ date: '2024-01-01', value: 8 }])
      end
    end
  end

  describe 'integration with real parser' do
    it 'calls parser with correct metric names and cutoff date' do
      expect(parser).to receive(:timeseries_for).with('tickets_created_ATS', since: cutoff_date)
      expect(parser).to receive(:timeseries_for).with('tickets_created_Platform', since: cutoff_date)
      expect(parser).to receive(:timeseries_for).with('tickets_created_Sourcing', since: cutoff_date)
      expect(parser).to receive(:timeseries_for).with('tickets_completed_ATS', since: cutoff_date)
      expect(parser).to receive(:timeseries_for).with('tickets_completed_Platform', since: cutoff_date)
      expect(parser).to receive(:timeseries_for).with('tickets_completed_Sourcing', since: cutoff_date)

      allow(parser).to receive(:timeseries_for).and_return([])

      aggregator.aggregate_timeseries('tickets_created', 'tickets_completed')
    end
  end
end
