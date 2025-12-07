# frozen_string_literal: true

RSpec.describe WttjMetrics::Reports::ChartDataBuilder do
  subject(:builder) { described_class.new(parser) }

  let(:parser) { instance_double(WttjMetrics::Data::CsvParser) }
  let(:status_metrics) do
    [
      { metric: 'Backlog', value: '50' },
      { metric: 'Todo', value: '30' },
      { metric: 'In Progress', value: '20' },
      { metric: 'Done', value: '100' }
    ]
  end

  let(:priority_metrics) do
    [
      { metric: 'High', value: '10' },
      { metric: 'Medium', value: '25' },
      { metric: 'Low', value: '15' }
    ]
  end

  let(:type_metrics) do
    [
      { metric: 'Feature', value: '40' },
      { metric: 'Bug', value: '15' },
      { metric: 'Improvement', value: '20' }
    ]
  end

  describe '#status_chart_data' do
    before do
      allow(parser).to receive(:metrics_for).with('status').and_return(status_metrics)
    end

    it 'returns chart data in the correct format' do
      result = builder.status_chart_data
      expect(result).to be_an(Array)
      expect(result.size).to eq(4)
    end

    it 'transforms metrics into label-value pairs with breakdown' do
      result = builder.status_chart_data
      expect(result.first).to have_key(:label)
      expect(result.first).to have_key(:value)
      expect(result.first).to have_key(:breakdown)
    end

    it 'converts string values to integers' do
      result = builder.status_chart_data
      result.each do |item|
        expect(item[:value]).to be_an(Integer)
      end
    end
  end

  describe '#priority_chart_data' do
    before do
      allow(parser).to receive(:metrics_for).with('priority').and_return(priority_metrics)
    end

    it 'returns chart data for priorities' do
      result = builder.priority_chart_data
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
    end

    it 'includes all priority levels' do
      result = builder.priority_chart_data
      labels = result.map { |item| item[:label] }
      expect(labels).to include('High', 'Medium', 'Low')
    end
  end

  describe '#type_chart_data' do
    before do
      allow(parser).to receive(:metrics_for).with('type').and_return(type_metrics)
    end

    it 'returns chart data for issue types' do
      result = builder.type_chart_data
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
    end

    it 'includes issue type information' do
      result = builder.type_chart_data
      expect(result).to include({ label: 'Feature', value: 40 })
      expect(result).to include({ label: 'Bug', value: 15 })
    end
  end

  describe '#assignee_chart_data' do
    let(:assignee_metrics) do
      [
        { metric: 'User A', value: 50 },
        { metric: 'User B', value: 30 },
        { metric: 'User C', value: 20 }
      ]
    end

    before do
      allow(parser).to receive(:metrics_for).with('assignee').and_return(assignee_metrics)
    end

    it 'returns assignees sorted by value descending' do
      result = builder.assignee_chart_data
      expect(result.size).to eq(3)
      expect(result.first[:label]).to eq('User A')
      expect(result.first[:value]).to eq(50)
    end

    context 'with more than 15 assignees' do
      let(:assignee_metrics) do
        (1..20).map do |i|
          { metric: "User #{i}", value: (21 - i) }
        end
      end

      it 'returns only top 15' do
        result = builder.assignee_chart_data
        expect(result.size).to eq(15)
      end
    end
  end

  context 'with empty metrics' do
    before do
      allow(parser).to receive(:metrics_for).and_return([])
    end

    it 'handles empty status metrics' do
      result = builder.status_chart_data
      expect(result).to eq([])
    end

    it 'handles empty priority metrics' do
      result = builder.priority_chart_data
      expect(result).to eq([])
    end

    it 'handles empty type metrics' do
      result = builder.type_chart_data
      expect(result).to eq([])
    end

    it 'handles empty assignee metrics' do
      result = builder.assignee_chart_data
      expect(result).to eq([])
    end
  end
end
