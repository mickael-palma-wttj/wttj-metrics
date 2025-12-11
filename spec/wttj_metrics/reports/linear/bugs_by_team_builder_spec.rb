# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Linear::BugsByTeamBuilder do
  let(:data_provider) { instance_double(WttjMetrics::Reports::Linear::DataProvider) }
  let(:selected_teams) { ['ATS', 'Platform', 'Global ATS'] }
  let(:builder) { described_class.new(data_provider, selected_teams) }

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
    it 'accepts a data_provider and selected teams' do
      expect { described_class.new(data_provider, selected_teams) }.not_to raise_error
    end
  end

  describe '#build' do
    before do
      allow(data_provider).to receive(:metrics_for)
        .with('bugs_by_team')
        .and_return(bugs_by_team_metrics)
    end

    it 'returns a hash of team statistics' do
      result = builder.build
      expect(result).to be_a(Hash)
    end

    it 'includes all selected teams' do
      result = builder.build
      expect(result.keys).to include('ATS', 'Platform', 'Global ATS')
    end

    it 'excludes non-selected teams' do
      result = builder.build
      expect(result.keys).not_to include('ROI')
    end

    it 'correctly parses integer values' do
      result = builder.build
      expect(result['ATS'][:created]).to eq(45)
      expect(result['ATS'][:closed]).to eq(38)
      expect(result['ATS'][:open]).to eq(7)
    end

    it 'correctly parses and rounds float values (mttr)' do
      result = builder.build
      expect(result['ATS'][:mttr]).to eq(49) # 48.5 rounded
      expect(result['Platform'][:mttr]).to eq(36) # 36.2 rounded
    end

    it 'sorts teams by open bugs descending' do
      result = builder.build
      # ATS (7) > Global ATS (3) > Platform (2)
      expect(result.keys).to eq(['ATS', 'Global ATS', 'Platform'])
    end

    context 'when data is missing for a team' do
      let(:bugs_by_team_metrics) do
        [
          { metric: 'ATS:created', value: 45 }
        ]
      end

      it 'fills missing stats with defaults' do
        result = builder.build
        expect(result['ATS']).to include(
          created: 45,
          closed: 0,
          open: 0,
          mttr: 0
        )
      end
    end
  end
end
