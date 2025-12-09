# frozen_string_literal: true

RSpec.describe WttjMetrics::Metrics::Linear::CycleParser do
  subject(:parser) { described_class.new(cycle_metrics, teams: selected_teams) }

  let(:selected_teams) { %w[Platform ATS] }
  let(:cycle_metrics) do
    [
      { date: '2024-12-01', metric: 'Platform:Cycle 10:total_issues', value: '25' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:completed_issues', value: '20' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:velocity', value: '42' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:completion_rate', value: '80.5' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:status', value: 'active' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:duration_days', value: '14' },
      { date: '2024-12-01', metric: 'Platform:Cycle 10:tickets_per_day', value: '1.43' },
      { date: '2024-12-01', metric: 'ATS:Cycle 5:total_issues', value: '15' },
      { date: '2024-12-01', metric: 'ATS:Cycle 5:completed_issues', value: '15' },
      { date: '2024-12-01', metric: 'ATS:Cycle 5:status', value: 'completed' },
      { date: '2024-12-01', metric: 'Backend:Cycle 3:total_issues', value: '10' }
    ]
  end

  describe '#parse' do
    subject(:result) { parser.parse }

    it 'returns a hash of cycles' do
      expect(result).to be_a(Hash)
    end

    it 'creates cycle keys from team and name' do
      expect(result).to have_key('Platform:Cycle 10')
      expect(result).to have_key('ATS:Cycle 5')
    end

    it 'parses cycle metadata' do
      cycle = result['Platform:Cycle 10']
      expect(cycle[:team]).to eq('Platform')
      expect(cycle[:name]).to eq('Cycle 10')
      expect(cycle[:date]).to eq('2024-12-01')
    end

    it 'parses integer metrics' do
      cycle = result['Platform:Cycle 10']
      expect(cycle[:total_issues]).to eq(25)
      expect(cycle[:completed_issues]).to eq(20)
      expect(cycle[:velocity]).to eq(42)
      expect(cycle[:duration_days]).to eq(14)
    end

    it 'parses float metrics with rounding' do
      cycle = result['Platform:Cycle 10']
      expect(cycle[:completion_rate]).to eq(81)
      expect(cycle[:tickets_per_day]).to eq(1)
    end

    it 'parses string metrics' do
      cycle = result['Platform:Cycle 10']
      expect(cycle[:status]).to eq('active')
    end

    context 'with invalid metric format' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'InvalidFormat', value: '10' },
          { date: '2024-12-01', metric: 'Team:Cycle', value: '10' }
        ]
      end

      it 'skips metrics without 3 parts' do
        expect(result).to be_empty
      end
    end

    context 'with unknown metric names' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Cycle 1:total_issues', value: '10' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:unknown_metric', value: '99' }
        ]
      end

      it 'ignores unknown metrics' do
        cycle = result['Platform:Cycle 1']
        expect(cycle[:total_issues]).to eq(10)
        expect(cycle).not_to have_key(:unknown_metric)
      end
    end

    context 'with all metric types' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Cycle 1:bug_count', value: '5' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:planned_points', value: '100' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:carryover', value: '3' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:progress', value: '75.5' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:assignee_count', value: '8' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:scope_change', value: '12.3' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:initial_scope', value: '50' },
          { date: '2024-12-01', metric: 'Platform:Cycle 1:final_scope', value: '56' }
        ]
      end

      it 'parses all metric types correctly' do
        cycle = result['Platform:Cycle 1']
        expect(cycle[:bug_count]).to eq(5)
        expect(cycle[:planned_points]).to eq(100)
        expect(cycle[:carryover]).to eq(3)
        expect(cycle[:progress]).to eq(76)
        expect(cycle[:assignee_count]).to eq(8)
        expect(cycle[:scope_change]).to eq(12)
        expect(cycle[:initial_scope]).to eq(50)
        expect(cycle[:final_scope]).to eq(56)
      end
    end
  end

  describe '#by_team' do
    subject(:result) { parser.by_team }

    it 'returns a hash grouped by team' do
      expect(result).to be_a(Hash)
      expect(result.keys).to include('Platform', 'ATS')
    end

    it 'filters by selected teams only' do
      expect(result.keys).to contain_exactly('Platform', 'ATS')
      expect(result.keys).not_to include('Backend')
    end

    it 'contains array of cycles per team' do
      expect(result['Platform']).to be_an(Array)
      expect(result['Platform'].first).to have_key(:team)
      expect(result['Platform'].first).to have_key(:name)
    end

    context 'with multiple cycles per team' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Cycle 10:total_issues', value: '25' },
          { date: '2024-12-01', metric: 'Platform:Cycle 10:status', value: 'completed' },
          { date: '2024-12-01', metric: 'Platform:Cycle 9:total_issues', value: '20' },
          { date: '2024-12-01', metric: 'Platform:Cycle 9:status', value: 'completed' },
          { date: '2024-12-01', metric: 'Platform:Cycle 11:total_issues', value: '30' },
          { date: '2024-12-01', metric: 'Platform:Cycle 11:status', value: 'active' }
        ]
      end

      it 'sorts cycles by number descending' do
        cycles = result['Platform']
        expect(cycles[0][:name]).to eq('Cycle 11')
        expect(cycles[1][:name]).to eq('Cycle 10')
        expect(cycles[2][:name]).to eq('Cycle 9')
      end
    end

    context 'with non-numeric cycle names' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Q4 Sprint:total_issues', value: '10' },
          { date: '2024-12-01', metric: 'Platform:Q4 Sprint:status', value: 'active' },
          { date: '2024-12-01', metric: 'Platform:Special:total_issues', value: '5' },
          { date: '2024-12-01', metric: 'Platform:Special:status', value: 'completed' }
        ]
      end

      it 'handles cycles without numbers' do
        cycles = result['Platform']
        expect(cycles.size).to eq(2)
      end
    end

    context 'with active and completed cycles' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Cycle 10:total_issues', value: '25' },
          { date: '2024-12-01', metric: 'Platform:Cycle 10:status', value: 'active' },
          { date: '2024-12-01', metric: 'ATS:Cycle 5:total_issues', value: '15' },
          { date: '2024-12-01', metric: 'ATS:Cycle 5:status', value: 'completed' }
        ]
      end

      it 'sorts teams with active cycles first' do
        teams = result.keys
        expect(teams.first).to eq('Platform') # has active cycle
        expect(teams.last).to eq('ATS') # has completed cycle
      end
    end

    context 'with teams having same cycle status' do
      let(:cycle_metrics) do
        [
          { date: '2024-12-01', metric: 'Platform:Cycle 10:total_issues', value: '25' },
          { date: '2024-12-01', metric: 'Platform:Cycle 10:status', value: 'completed' },
          { date: '2024-12-01', metric: 'ATS:Cycle 5:total_issues', value: '15' },
          { date: '2024-12-01', metric: 'ATS:Cycle 5:status', value: 'completed' }
        ]
      end

      it 'sorts teams alphabetically when same status' do
        teams = result.keys
        expect(teams).to eq(%w[ATS Platform])
      end
    end

    context 'with default teams' do
      subject(:parser) { described_class.new(cycle_metrics) }

      it 'uses default teams when none provided' do
        expect(result).to be_a(Hash)
      end
    end

    context 'with empty metrics' do
      let(:cycle_metrics) { [] }

      it 'returns empty hash' do
        expect(result).to eq({})
      end
    end
  end
end
