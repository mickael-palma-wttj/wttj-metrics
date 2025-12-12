# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Metrics::Linear::TicketActivityCalculator do
  subject(:calculator) { described_class.new(issues) }

  let(:issues) do
    [
      { 'completedAt' => '2023-01-02T10:00:00Z', 'assignee' => { 'name' => 'Alice' } }, # Monday 10am
      { 'completedAt' => '2023-01-02T10:30:00Z', 'assignee' => { 'name' => 'Bob' } }, # Monday 10am
      { 'completedAt' => '2023-01-03T14:00:00Z', 'assignee' => { 'name' => 'Alice' } }, # Tuesday 2pm
      { 'completedAt' => nil } # Should be ignored
    ]
  end

  describe '#calculate' do
    it 'calculates ticket activity by day and hour' do
      result = calculator.calculate

      expect(result).to include(
        hash_including(wday: 1, hour: 10, value: { count: 2, authors: { 'Alice' => 1, 'Bob' => 1 } }.to_json),
        hash_including(wday: 2, hour: 14, value: { count: 1, authors: { 'Alice' => 1 } }.to_json)
      )
    end
  end

  describe '#to_rows' do
    it 'returns formatted rows for CSV' do
      rows = calculator.to_rows

      expect(rows).to include(
        [Date.today.to_s, 'linear_ticket_activity', '1_10',
         { count: 2, authors: { 'Alice' => 1, 'Bob' => 1 } }.to_json],
        [Date.today.to_s, 'linear_ticket_activity', '2_14', { count: 1, authors: { 'Alice' => 1 } }.to_json]
      )
    end
  end
end
