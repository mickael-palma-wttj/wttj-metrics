# frozen_string_literal: true

RSpec.describe WttjMetrics::Metrics::Linear::TimeseriesCalculator do
  subject(:collector) { described_class.new(issues, today: today) }

  # Setup
  let(:today) { Date.new(2024, 12, 5) }
  let(:issues) { [] }

  describe '#to_rows' do
    subject(:rows) { collector.to_rows }

    context 'with issues created and completed' do
      # Setup
      let(:issues) do
        [
          {
            'createdAt' => '2024-12-01T10:00:00Z',
            'completedAt' => '2024-12-03T10:00:00Z',
            'team' => { 'name' => 'Platform' },
            'state' => { 'type' => 'completed' },
            'labels' => { 'nodes' => [] }
          },
          {
            'createdAt' => '2024-12-01T14:00:00Z',
            'completedAt' => nil,
            'team' => { 'name' => 'Platform' },
            'state' => { 'type' => 'started' },
            'labels' => { 'nodes' => [] }
          }
        ]
      end

      it 'includes ticket creation timeseries' do
        created_rows = rows.select { |r| r[2] == 'tickets_created' }
        expect(created_rows).not_to be_empty
      end

      it 'includes ticket completion timeseries' do
        completed_rows = rows.select { |r| r[2] == 'tickets_completed' }
        expect(completed_rows).not_to be_empty
      end

      it 'includes team-specific timeseries' do
        team_rows = rows.select { |r| r[2].include?('Platform') }
        expect(team_rows).not_to be_empty
      end

      it 'counts tickets by date', :aggregate_failures do
        dec_1_created = rows.find { |r| r[0] == '2024-12-01' && r[2] == 'tickets_created' }
        expect(dec_1_created[3]).to eq(2)
      end
    end

    context 'with bug issues' do
      # Setup
      let(:issues) do
        [
          {
            'createdAt' => '2024-12-01T10:00:00Z',
            'completedAt' => '2024-12-02T10:00:00Z',
            'team' => { 'name' => 'ATS' },
            'state' => { 'type' => 'completed' },
            'labels' => { 'nodes' => [{ 'name' => 'bug' }] }
          }
        ]
      end

      it 'includes bug creation timeseries' do
        bug_created = rows.select { |r| r[2] == 'bugs_created' }
        expect(bug_created).not_to be_empty
      end

      it 'includes bug closed timeseries' do
        bug_closed = rows.select { |r| r[2] == 'bugs_closed' }
        expect(bug_closed).not_to be_empty
      end

      it 'includes bugs by team stats', :aggregate_failures do
        team_bugs = rows.select { |r| r[1] == 'bugs_by_team' }

        expect(team_bugs).not_to be_empty
        expect(team_bugs.map { |r| r[2] }).to include('ATS:created', 'ATS:closed')
      end
    end

    context 'with state transitions' do
      # Setup
      let(:issues) do
        [
          {
            'createdAt' => '2024-12-01T10:00:00Z',
            'team' => { 'name' => 'Platform' },
            'state' => { 'type' => 'started' },
            'labels' => { 'nodes' => [] },
            'history' => {
              'nodes' => [
                {
                  'createdAt' => '2024-12-02T10:00:00Z',
                  'toState' => { 'name' => 'In Progress' }
                },
                {
                  'createdAt' => '2024-12-03T10:00:00Z',
                  'toState' => { 'name' => 'In Review' }
                }
              ]
            }
          }
        ]
      end

      it 'includes transition rows' do
        transition_rows = rows.select { |r| r[1] == 'transition_to' }
        expect(transition_rows).not_to be_empty
      end

      it 'counts transitions by state', :aggregate_failures do
        states = rows.select { |r| r[1] == 'transition_to' }.map { |r| r[2] }

        expect(states).to include('In Progress', 'In Review')
      end

      it 'includes team-specific transitions' do
        team_transitions = rows.select { |r| r[1] == 'transition_to' && r[2].include?('Platform:') }
        expect(team_transitions).not_to be_empty
      end
    end

    context 'with no issues' do
      # Setup
      let(:issues) { [] }

      it 'returns empty array' do
        expect(rows).to be_empty
      end
    end

    context 'with issues missing team' do
      # Setup
      let(:issues) do
        [
          {
            'createdAt' => '2024-12-01T10:00:00Z',
            'team' => nil,
            'state' => { 'type' => 'backlog' },
            'labels' => { 'nodes' => [] }
          }
        ]
      end

      it 'uses Unknown as team name' do
        team_rows = rows.select { |r| r[2].include?('Unknown') }
        expect(team_rows).not_to be_empty
      end
    end
  end
end
