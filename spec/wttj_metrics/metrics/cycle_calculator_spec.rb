# frozen_string_literal: true

RSpec.describe WttjMetrics::Metrics::CycleCalculator do
  subject(:calculator) { described_class.new(cycles, today: today) }

  # Setup
  let(:today) { Date.new(2024, 12, 5) }
  let(:cycles) { [] }

  describe '#calculate' do
    subject(:result) { calculator.calculate }

    context 'with active cycle' do
      # Setup
      let(:cycles) do
        [
          {
            'name' => 'Sprint 1',
            'startsAt' => '2024-12-01',
            'endsAt' => '2024-12-14',
            'issues' => {
              'nodes' => [
                { 'estimate' => 3, 'state' => { 'type' => 'completed' } },
                { 'estimate' => 5, 'state' => { 'type' => 'completed' } },
                { 'estimate' => 2, 'state' => { 'type' => 'started' } }
              ]
            }
          }
        ]
      end

      it 'calculates current cycle velocity' do
        # 3 + 5 = 8 points completed
        expect(result[:current_cycle_velocity]).to eq(8)
      end

      it 'calculates commitment accuracy' do
        # 2 out of 3 issues completed = 66.67%
        expect(result[:cycle_commitment_accuracy]).to be_within(0.1).of(66.67)
      end
    end

    context 'with completed cycle' do
      # Setup
      let(:cycles) do
        [
          {
            'name' => 'Sprint 0',
            'startsAt' => '2024-11-15',
            'endsAt' => '2024-11-30',
            'completedAt' => '2024-11-30T10:00:00Z',
            'issues' => { 'nodes' => [] },
            'uncompletedIssuesUponClose' => {
              'nodes' => [{ 'id' => '1' }, { 'id' => '2' }]
            }
          }
        ]
      end

      it 'calculates carryover count from last completed cycle' do
        expect(result[:cycle_carryover_count]).to eq(2)
      end
    end

    context 'with no cycles' do
      # Setup
      let(:cycles) { [] }

      it 'returns zero for all metrics', :aggregate_failures do
        expect(result[:current_cycle_velocity]).to eq(0)
        expect(result[:cycle_commitment_accuracy]).to eq(0)
        expect(result[:cycle_carryover_count]).to eq(0)
      end
    end
  end

  describe '#to_rows' do
    subject(:rows) { calculator.to_rows }

    context 'with cycles' do
      # Setup
      let(:cycles) do
        [
          {
            'name' => 'Sprint 1',
            'number' => 1,
            'startsAt' => '2024-12-01',
            'endsAt' => '2024-12-14',
            'progress' => 0.5,
            'team' => { 'name' => 'Team A' },
            'issues' => {
              'nodes' => [
                { 'estimate' => 3, 'state' => { 'type' => 'completed' }, 'assignee' => { 'id' => 'u1' } }
              ]
            },
            'uncompletedIssuesUponClose' => { 'nodes' => [] }
          }
        ]
      end

      it 'includes cycle metrics rows' do
        cycle_metrics = rows.select { |r| r[1] == 'cycle_metrics' }

        expect(cycle_metrics.map { |r| r[2] }).to include(
          'current_cycle_velocity',
          'cycle_commitment_accuracy',
          'cycle_carryover_count'
        )
      end

      it 'includes cycle detail rows', :aggregate_failures do
        cycle_details = rows.select { |r| r[1] == 'cycle' }

        expect(cycle_details).not_to be_empty
        expect(cycle_details.first[2]).to start_with('Team A:Sprint 1:')
      end
    end
  end
end
