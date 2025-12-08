# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Presenters::TeamMetricPresenter do
  subject(:presenter) { described_class.new(metric) }

  let(:metric) { { metric: metric_name, value: metric_value } }
  let(:metric_name) { 'completion_rate' }
  let(:metric_value) { 85.5 }

  it_behaves_like 'a presenter'

  describe '#label' do
    subject(:label) { presenter.label }

    context 'with completion_rate' do
      let(:metric_name) { 'completion_rate' }

      it 'formats the label' do
        expect(label).to eq('Completion rate')
      end
    end

    context 'with avg_blocked_time_hours' do
      let(:metric_name) { 'avg_blocked_time_hours' }

      it 'formats with Avg capitalized' do
        expect(label).to eq('Avg blocked time hours')
      end
    end
  end

  describe '#tooltip' do
    subject(:tooltip) { presenter.tooltip }

    context 'with completion_rate' do
      let(:metric_name) { 'completion_rate' }

      it 'returns the tooltip' do
        expect(tooltip).to eq('Percentage of issues completed vs total issues.')
      end
    end

    context 'with avg_blocked_time_hours' do
      let(:metric_name) { 'avg_blocked_time_hours' }

      it 'returns the tooltip' do
        expect(tooltip).to eq('Average hours issues spend in blocked state.')
      end
    end

    context 'with unknown metric' do
      let(:metric_name) { 'unknown_metric' }

      it 'returns empty string' do
        expect(tooltip).to eq('')
      end
    end
  end

  describe '#unit' do
    subject(:unit) { presenter.unit }

    context 'with rate metric' do
      let(:metric_name) { 'completion_rate' }

      it 'returns percentage unit' do
        expect(unit).to eq('%')
      end
    end

    context 'with hours metric' do
      let(:metric_name) { 'avg_blocked_time_hours' }

      it 'returns hours unit' do
        expect(unit).to eq('h')
      end
    end

    context 'with other metric' do
      let(:metric_name) { 'some_metric' }

      it 'returns empty string' do
        expect(unit).to eq('')
      end
    end
  end
end
