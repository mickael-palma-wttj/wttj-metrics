# frozen_string_literal: true

RSpec.describe WttjMetrics::Presenters::CyclePresenter do
  subject(:presenter) { described_class.new(cycle) }

  # Setup
  let(:cycle) do
    {
      name: 'Sprint 1',
      status: 'active',
      progress: 75.0,
      completed_issues: 8,
      total_issues: 10,
      bug_count: 2,
      assignee_count: 3,
      velocity: 20,
      tickets_per_day: 0.8,
      completion_rate: 80.0,
      carryover: 1,
      scope_change: scope_change
    }
  end
  let(:scope_change) { 15.5 }

  describe '#scope_change' do
    subject(:result) { presenter.scope_change }

    it 'returns the scope change value' do
      expect(result).to eq(15.5)
    end

    context 'when scope_change is nil' do
      let(:scope_change) { nil }

      it 'returns 0' do
        expect(result).to eq(0)
      end
    end
  end

  describe '#scope_change_display' do
    subject(:result) { presenter.scope_change_display }

    it 'formats scope change with percent sign' do
      expect(result).to eq('15.5%')
    end

    context 'when scope_change is nil' do
      let(:scope_change) { nil }

      it 'returns 0%' do
        expect(result).to eq('0%')
      end
    end
  end

  describe '#scope_change_class' do
    subject(:result) { presenter.scope_change_class }

    context 'when scope_change is positive' do
      let(:scope_change) { 15.5 }

      it 'returns scope-increase class' do
        expect(result).to eq('scope-increase')
      end
    end

    context 'when scope_change is negative' do
      let(:scope_change) { -10.0 }

      it 'returns scope-decrease class' do
        expect(result).to eq('scope-decrease')
      end
    end

    context 'when scope_change is zero' do
      let(:scope_change) { 0 }

      it 'returns scope-neutral class' do
        expect(result).to eq('scope-neutral')
      end
    end

    context 'when scope_change is nil' do
      let(:scope_change) { nil }

      it 'returns scope-neutral class' do
        expect(result).to eq('scope-neutral')
      end
    end
  end

  describe '#to_h' do
    subject(:result) { presenter.to_h }

    it 'includes scope_change fields', :aggregate_failures do
      expect(result[:scope_change]).to eq(15.5)
      expect(result[:scope_change_display]).to eq('15.5%')
      expect(result[:scope_change_class]).to eq('scope-increase')
    end
  end
end
