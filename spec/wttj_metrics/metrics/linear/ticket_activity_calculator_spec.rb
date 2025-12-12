# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Metrics::Linear::TicketActivityCalculator do
  subject(:calculator) { described_class.new(issues) }

  let(:issues) do
    [
      { 'completedAt' => '2023-01-02T10:00:00Z' }, # Monday 10am
      { 'completedAt' => '2023-01-02T10:30:00Z' }, # Monday 10am
      { 'completedAt' => '2023-01-03T14:00:00Z' }, # Tuesday 2pm
      { 'completedAt' => nil } # Should be ignored
    ]
  end

  describe '#calculate' do
    it 'calculates ticket activity by day and hour' do
      result = calculator.calculate

      expect(result).to include(
        hash_including(wday: 1, hour: 10, value: 2),
        hash_including(wday: 2, hour: 14, value: 1)
      )
    end
  end

  describe '#to_rows' do
    it 'returns formatted rows for CSV' do
      rows = calculator.to_rows

      expect(rows).to include(
        [Date.today.to_s, 'linear_ticket_activity', '1_10', 2],
        [Date.today.to_s, 'linear_ticket_activity', '2_14', 1]
      )
    end
  end
end
