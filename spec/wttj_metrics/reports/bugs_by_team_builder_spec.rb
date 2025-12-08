# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::BugsByTeamBuilder do
  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:selected_teams) { ['ATS', 'Platform', 'Global ATS'] }
  let(:builder) { described_class.new(parser, selected_teams) }

  let(:bugs_by_team_metrics) do
    [
      { metric: 'ATS:created', value: 45 },
      { metric: 'ATS:closed', value: 38 },
      { metric: 'ATS:open', value: 7 },
      { metric: 'ATS:mttr', value: 48.5 },
      { metric: 'Platform:created', value: 32 },
      { metric: 'Platform:closed', value: 30 },
      { metric: 'Platform:open', value: 2 },
      { metric: 'Platform:mttr', value: 36.2 },
      { metric: 'Global ATS:created', value: 28 },
      { metric: 'Global ATS:closed', value: 25 },
      { metric: 'Global ATS:open', value: 3 },
      { metric: 'Global ATS:mttr', value: 52.8 },
      { metric: 'ROI:created', value: 15 },
      { metric: 'ROI:closed', value: 14 },
      { metric: 'ROI:open', value: 1 },
      { metric: 'ROI:mttr', value: 24.0 }
    ]
  end

  describe '#initialize' do
    it 'accepts a parser and selected teams' do
      expect { described_class.new(parser, selected_teams) }.not_to raise_error
    end
  end

  describe '#build' do
    before do
      allow(parser).to receive(:metrics_for)
        .with('bugs_by_team')
        .and_return(bugs_by_team_metrics)
    end

    it 'returns a hash of team statistics' do
      result = builder.build
      expect(result).to be_a(Hash)
    end

    it 'includes all selected teams' do
      result = builder.build
      expect(result.keys).to contain_exactly('ATS', 'Platform', 'Global ATS')
    end

    it 'excludes teams not in selected_teams' do
      result = builder.build
      expect(result.keys).not_to include('ROI')
    end

    it 'aggregates created count for each team' do
      result = builder.build
      expect(result['ATS'][:created]).to eq(45)
      expect(result['Platform'][:created]).to eq(32)
      expect(result['Global ATS'][:created]).to eq(28)
    end

    it 'aggregates closed count for each team' do
      result = builder.build
      expect(result['ATS'][:closed]).to eq(38)
      expect(result['Platform'][:closed]).to eq(30)
      expect(result['Global ATS'][:closed]).to eq(25)
    end

    it 'aggregates open count for each team' do
      result = builder.build
      expect(result['ATS'][:open]).to eq(7)
      expect(result['Platform'][:open]).to eq(2)
      expect(result['Global ATS'][:open]).to eq(3)
    end

    it 'rounds MTTR values to integers' do
      result = builder.build
      expect(result['ATS'][:mttr]).to eq(49)
      expect(result['Platform'][:mttr]).to eq(36)
      expect(result['Global ATS'][:mttr]).to eq(53)
    end

    it 'sorts teams by open bugs descending' do
      result = builder.build
      teams = result.keys
      open_counts = teams.map { |team| result[team][:open] }

      expect(open_counts).to eq(open_counts.sort.reverse)
      expect(teams.first).to eq('ATS') # 7 open bugs
    end

    context 'with empty metrics' do
      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return([])
      end

      it 'returns empty hash' do
        result = builder.build
        expect(result).to eq({})
      end
    end

    context 'with missing stats for a team' do
      let(:incomplete_metrics) do
        [
          { metric: 'ATS:created', value: 10 },
          { metric: 'ATS:open', value: 5 }
          # Missing closed and mttr
        ]
      end

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(incomplete_metrics)
      end

      it 'uses default values for missing stats' do
        result = builder.build
        expect(result['ATS'][:created]).to eq(10)
        expect(result['ATS'][:closed]).to eq(0)
        expect(result['ATS'][:open]).to eq(5)
        expect(result['ATS'][:mttr]).to eq(0)
      end
    end

    context 'with zero open bugs' do
      let(:all_closed_metrics) do
        [
          { metric: 'ATS:created', value: 10 },
          { metric: 'ATS:closed', value: 10 },
          { metric: 'ATS:open', value: 0 },
          { metric: 'ATS:mttr', value: 24.0 }
        ]
      end

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(all_closed_metrics)
      end

      it 'includes teams with zero open bugs' do
        result = builder.build
        expect(result['ATS']).to be_present
        expect(result['ATS'][:open]).to eq(0)
      end
    end

    context 'with special characters in team names' do
      let(:special_teams) { ['ATS', 'Platform & Tools'] }
      let(:special_metrics) do
        [
          { metric: 'Platform & Tools:created', value: 5 },
          { metric: 'Platform & Tools:closed', value: 4 },
          { metric: 'Platform & Tools:open', value: 1 },
          { metric: 'Platform & Tools:mttr', value: 30.0 }
        ]
      end

      let(:special_builder) { described_class.new(parser, special_teams) }

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(special_metrics)
      end

      it 'handles teams with special characters' do
        result = special_builder.build
        expect(result['Platform & Tools']).to be_present
        expect(result['Platform & Tools'][:created]).to eq(5)
      end
    end
  end

  describe 'metric parsing' do
    let(:malformed_metrics) do
      [
        { metric: 'NoColon', value: 10 },
        { metric: 'ATS:created', value: 5 }
      ]
    end

    before do
      allow(parser).to receive(:metrics_for)
        .with('bugs_by_team')
        .and_return(malformed_metrics)
    end

    it 'handles metrics without colon gracefully' do
      expect { builder.build }.not_to raise_error
    end
  end

  describe 'data types' do
    before do
      allow(parser).to receive(:metrics_for)
        .with('bugs_by_team')
        .and_return(bugs_by_team_metrics)
    end

    it 'returns integers for created' do
      result = builder.build
      expect(result['ATS'][:created]).to be_an(Integer)
    end

    it 'returns integers for closed' do
      result = builder.build
      expect(result['ATS'][:closed]).to be_an(Integer)
    end

    it 'returns integers for open' do
      result = builder.build
      expect(result['ATS'][:open]).to be_an(Integer)
    end

    it 'returns integers for mttr' do
      result = builder.build
      expect(result['ATS'][:mttr]).to be_an(Integer)
    end
  end

  describe 'hash structure' do
    before do
      allow(parser).to receive(:metrics_for)
        .with('bugs_by_team')
        .and_return(bugs_by_team_metrics)
    end

    it 'returns hash with symbol keys for stats' do
      result = builder.build
      expect(result['ATS'].keys).to all(be_a(Symbol))
    end

    it 'includes all expected stats' do
      result = builder.build
      expect(result['ATS'].keys).to contain_exactly(:created, :closed, :open, :mttr)
    end
  end

  describe 'edge cases' do
    context 'with very large MTTR values' do
      let(:large_mttr_metrics) do
        [
          { metric: 'ATS:created', value: 1 },
          { metric: 'ATS:closed', value: 1 },
          { metric: 'ATS:open', value: 0 },
          { metric: 'ATS:mttr', value: 999_999.999 }
        ]
      end

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(large_mttr_metrics)
      end

      it 'rounds very large MTTR values correctly' do
        result = builder.build
        expect(result['ATS'][:mttr]).to eq(1_000_000)
      end
    end

    context 'with negative values' do
      let(:negative_metrics) do
        [
          { metric: 'ATS:created', value: -5 },
          { metric: 'ATS:closed', value: 10 },
          { metric: 'ATS:open', value: -15 },
          { metric: 'ATS:mttr', value: 30.0 }
        ]
      end

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(negative_metrics)
      end

      it 'preserves negative values' do
        result = builder.build
        expect(result['ATS'][:created]).to eq(-5)
        expect(result['ATS'][:open]).to eq(-15)
      end
    end

    context 'with empty selected_teams' do
      let(:empty_builder) { described_class.new(parser, []) }

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(bugs_by_team_metrics)
      end

      it 'returns empty hash' do
        result = empty_builder.build
        expect(result).to eq({})
      end
    end
  end
end
