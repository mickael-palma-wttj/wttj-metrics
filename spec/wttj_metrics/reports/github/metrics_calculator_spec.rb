# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Github::MetricsCalculator do
  subject(:calculator) { described_class.new(metrics_data) }

  let(:metrics_data) do
    [
      { date: '2024-01-01', metric: 'pr_velocity', value: 5 },
      { date: '2024-01-02', metric: 'pr_velocity', value: 8 },
      { date: '2024-01-01', metric: 'other_metric', value: 10 }
    ]
  end

  describe '#latest' do
    it 'returns the value of the latest metric' do
      expect(calculator.latest('pr_velocity')).to eq(8)
    end

    it 'returns 0 if metric not found' do
      expect(calculator.latest('unknown')).to eq(0)
    end
  end

  describe '#history' do
    it 'returns sorted history of the metric' do
      history = calculator.history('pr_velocity')
      expect(history).to eq([
                              { date: '2024-01-01', value: 5 },
                              { date: '2024-01-02', value: 8 }
                            ])
    end

    it 'returns empty array if metric not found' do
      expect(calculator.history('unknown')).to eq([])
    end
  end

  context 'with nil data' do
    subject(:calculator) { described_class.new(nil) }

    it 'handles nil data gracefully' do
      expect(calculator.latest('any')).to eq(0)
      expect(calculator.history('any')).to eq([])
    end
  end
end
