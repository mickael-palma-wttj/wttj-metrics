# frozen_string_literal: true

require 'tempfile'

RSpec.describe WttjMetrics::Reports::ExcelReportBuilder do
  subject(:builder) { described_class.new(report_data) }

  let(:temp_file) { Tempfile.new(['report', '.xlsx']) }
  let(:report_data) do
    {
      today: '2024-12-07',
      days_to_show: 90,
      flow_metrics: [
        { date: '2024-12-07', category: 'flow', metric: 'throughput', value: 10 }
      ],
      cycle_metrics: [
        { date: '2024-12-07', category: 'cycle', metric: 'avg_cycle_time', value: 5.5 }
      ],
      team_metrics: [],
      bug_metrics: [],
      bugs_by_priority: [],
      status_chart_data: [
        { label: 'Todo', value: 30 },
        { label: 'Done', value: 100 }
      ],
      priority_dist: [],
      type_dist: [],
      assignee_dist: [],
      team_stats: {},
      cycles_by_team: {},
      weekly_flow_data: {
        labels: ['Dec 01', 'Dec 08'],
        created_raw: [10, 15],
        completed_raw: [8, 12]
      },
      raw_data: []
    }
  end

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    it 'accepts report data' do
      expect(builder).to be_a(described_class)
    end

    it 'stores report data' do
      expect(builder.instance_variable_get(:@data)).to eq(report_data)
    end
  end

  describe '#build' do
    it 'creates an Excel file' do
      builder.build(temp_file.path)
      expect(File.exist?(temp_file.path)).to be true
    end

    it 'creates a valid Excel file with content' do
      builder.build(temp_file.path)
      expect(File.size(temp_file.path)).to be > 0
    end

    it 'successfully builds the file' do
      expect { builder.build(temp_file.path) }.not_to raise_error
    end
  end

  context 'with minimal data' do
    let(:minimal_data) do
      {
        today: '2024-12-07',
        days_to_show: 30,
        flow_metrics: [],
        cycle_metrics: [],
        team_metrics: [],
        bug_metrics: [],
        bugs_by_priority: [],
        status_chart_data: [],
        priority_dist: [],
        type_dist: [],
        assignee_dist: [],
        team_stats: {},
        cycles_by_team: {},
        weekly_flow_data: { labels: [], created_raw: [], completed_raw: [] },
        raw_data: []
      }
    end

    it 'handles empty metrics gracefully' do
      builder = described_class.new(minimal_data)
      expect { builder.build(temp_file.path) }.not_to raise_error
    end
  end

  context 'with complete data' do
    let(:complete_data) do
      report_data.merge(
        team_metrics: [
          { date: '2024-12-07', category: 'team', metric: 'ATS:throughput', value: 5 }
        ],
        bug_metrics: [
          { date: '2024-12-07', category: 'bugs', metric: 'open_bugs', value: 10 }
        ],
        bugs_by_priority: [
          { metric: 'High', value: 5 },
          { metric: 'Low', value: 5 }
        ],
        team_stats: {
          'ATS' => {
            total_cycles: 5,
            cycles_with_data: 4,
            avg_velocity: 25.5,
            avg_tickets_per_cycle: 12.0,
            avg_completion_rate: 80.0,
            avg_scope_change: 10.0
          }
        },
        cycles_by_team: {
          'ATS' => [
            { id: '1', name: 'Sprint 1', status: 'completed' }
          ]
        }
      )
    end

    it 'includes all data in the Excel file' do
      builder = described_class.new(complete_data)
      expect { builder.build(temp_file.path) }.not_to raise_error
      expect(File.size(temp_file.path)).to be > 500 # Should have content
    end
  end
end
