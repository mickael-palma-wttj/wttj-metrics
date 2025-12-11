# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Linear::TeamFilter do
  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:bugs_by_team_metrics) do
    [
      { metric: 'ATS:created', value: 45 },
      { metric: 'Global ATS:created', value: 32 },
      { metric: 'Platform:created', value: 28 },
      { metric: 'Unknown:created', value: 5 },
      { metric: 'ROI:created', value: 12 }
    ]
  end

  describe '#initialize' do
    it 'accepts a parser instance' do
      expect { described_class.new(parser) }.not_to raise_error
    end

    it 'accepts an optional teams parameter' do
      expect { described_class.new(parser, teams: ['ATS']) }.not_to raise_error
    end
  end

  describe '#selected_teams' do
    context 'when teams parameter is nil' do
      let(:filter) { described_class.new(parser, teams: nil) }

      it 'returns default teams' do
        expect(filter.selected_teams).to eq(described_class::DEFAULT_TEAMS)
      end

      it 'includes expected default teams' do
        expect(filter.selected_teams).to include('ATS', 'Global ATS', 'Marketplace', 'Platform')
      end
    end

    context 'when teams parameter is :all' do
      let(:filter) { described_class.new(parser, teams: :all) }

      before do
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(bugs_by_team_metrics)
      end

      it 'discovers all teams from metrics' do
        expect(filter.selected_teams).to contain_exactly('ATS', 'Global ATS', 'Platform', 'ROI')
      end

      it 'excludes Unknown team' do
        expect(filter.selected_teams).not_to include('Unknown')
      end

      it 'sorts teams alphabetically' do
        expect(filter.selected_teams).to eq(['ATS', 'Global ATS', 'Platform', 'ROI'])
      end

      it 'returns unique teams' do
        duplicate_metrics = bugs_by_team_metrics + [{ metric: 'ATS:closed', value: 40 }]
        allow(parser).to receive(:metrics_for)
          .with('bugs_by_team')
          .and_return(duplicate_metrics)

        teams = filter.selected_teams
        expect(teams.count('ATS')).to eq(1)
      end
    end

    context 'when teams parameter is a custom array' do
      let(:custom_teams) { %w[ATS Platform] }
      let(:filter) { described_class.new(parser, teams: custom_teams) }

      it 'returns the custom teams array' do
        expect(filter.selected_teams).to eq(custom_teams)
      end

      it 'does not call parser when using custom teams' do
        expect(parser).not_to receive(:metrics_for)
        filter.selected_teams
      end
    end

    context 'when teams parameter is omitted' do
      let(:filter) { described_class.new(parser) }

      it 'returns default teams' do
        expect(filter.selected_teams).to eq(described_class::DEFAULT_TEAMS)
      end
    end
  end

  describe '#all_teams_mode?' do
    context 'when teams is :all' do
      let(:filter) { described_class.new(parser, teams: :all) }

      it 'returns true' do
        allow(parser).to receive(:metrics_for).and_return(bugs_by_team_metrics)
        expect(filter.all_teams_mode?).to be true
      end
    end

    context 'when teams is nil' do
      let(:filter) { described_class.new(parser, teams: nil) }

      it 'returns false' do
        expect(filter.all_teams_mode?).to be false
      end
    end
  end
end
