# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Linear::MetricAccessor do
  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:accessor) { described_class.new(parser) }

  describe '#initialize' do
    it 'accepts a parser instance' do
      expect { described_class.new(parser) }.not_to raise_error
    end
  end

  describe '#flow_metrics' do
    let(:flow_data) { [{ metric: 'cycle_time', value: 5.2 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('flow').and_return(flow_data)
      expect(accessor.flow_metrics).to eq(flow_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('flow').once.and_return(flow_data)
      2.times { accessor.flow_metrics }
    end
  end

  describe '#cycle_metrics' do
    let(:cycle_data) { [{ metric: 'velocity', value: 25 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('cycle_metrics').and_return(cycle_data)
      expect(accessor.cycle_metrics).to eq(cycle_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('cycle_metrics').once.and_return(cycle_data)
      2.times { accessor.cycle_metrics }
    end
  end

  describe '#team_metrics' do
    let(:team_data) { [{ metric: 'ATS:velocity', value: 30 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('team').and_return(team_data)
      expect(accessor.team_metrics).to eq(team_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('team').once.and_return(team_data)
      2.times { accessor.team_metrics }
    end
  end

  describe '#bug_metrics' do
    let(:bug_data) { [{ metric: 'total_bugs', value: 150 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('bugs').and_return(bug_data)
      expect(accessor.bug_metrics).to eq(bug_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('bugs').once.and_return(bug_data)
      2.times { accessor.bug_metrics }
    end
  end

  describe '#bugs_by_priority' do
    let(:priority_data) { [{ metric: 'High', value: 50 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('bugs_by_priority').and_return(priority_data)
      expect(accessor.bugs_by_priority).to eq(priority_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('bugs_by_priority').once.and_return(priority_data)
      2.times { accessor.bugs_by_priority }
    end
  end

  describe '#status_dist' do
    let(:status_data) { [{ metric: 'In Progress', value: 45 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('status').and_return(status_data)
      expect(accessor.status_dist).to eq(status_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('status').once.and_return(status_data)
      2.times { accessor.status_dist }
    end
  end

  describe '#priority_dist' do
    let(:priority_data) { [{ metric: 'High', value: 100 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('priority').and_return(priority_data)
      expect(accessor.priority_dist).to eq(priority_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('priority').once.and_return(priority_data)
      2.times { accessor.priority_dist }
    end
  end

  describe '#type_dist' do
    let(:type_data) { [{ metric: 'Bug', value: 80 }] }

    it 'delegates to parser.metrics_for' do
      allow(parser).to receive(:metrics_for).with('type').and_return(type_data)
      expect(accessor.type_dist).to eq(type_data)
    end

    it 'memoizes the result' do
      expect(parser).to receive(:metrics_for).with('type').once.and_return(type_data)
      2.times { accessor.type_dist }
    end
  end

  describe '#assignee_dist' do
    let(:assignee_data) do
      [
        { metric: 'User A', value: 10 },
        { metric: 'User B', value: 20 },
        { metric: 'User C', value: 5 }
      ]
    end

    it 'delegates to parser.metrics_for and sorts/limits' do
      allow(parser).to receive(:metrics_for).with('assignee').and_return(assignee_data)

      result = accessor.assignee_dist
      expect(result.first[:metric]).to eq('User B')
      expect(result.last[:metric]).to eq('User C')
    end

    it 'memoizes the result' do
      allow(parser).to receive(:metrics_for).with('assignee').and_return(assignee_data)
      expect(parser).to receive(:metrics_for).with('assignee').once
      2.times { accessor.assignee_dist }
    end
  end
end
