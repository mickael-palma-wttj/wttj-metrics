# frozen_string_literal: true

RSpec.describe WttjMetrics::Presenters::CyclePresenter do
  subject(:presenter) { described_class.new(cycle) }

  let(:cycle) do
    {
      name: 'Cycle 10',
      status: 'active',
      progress: 75.5,
      completed_issues: 20,
      total_issues: 25,
      bug_count: 3,
      assignee_count: 8,
      velocity: 42,
      tickets_per_day: 1.43,
      completion_rate: 80.0,
      carryover: 2,
      scope_change: 15.5,
      initial_scope: 20,
      final_scope: 23
    }
  end

  describe '#name' do
    it 'returns the cycle name' do
      expect(presenter.name).to eq('Cycle 10')
    end
  end

  describe '#status' do
    it 'returns the cycle status' do
      expect(presenter.status).to eq('active')
    end
  end

  describe '#status_class' do
    it 'returns the status class' do
      expect(presenter.status_class).to eq('status-active')
    end
  end

  describe '#progress' do
    it 'returns the progress value' do
      expect(presenter.progress).to eq(75.5)
    end

    context 'when progress is nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.progress).to eq(0)
      end
    end
  end

  describe '#completed_issues and #total_issues' do
    it 'returns completed issues' do
      expect(presenter.completed_issues).to eq(20)
    end

    it 'returns total issues' do
      expect(presenter.total_issues).to eq(25)
    end

    context 'when values are nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0 for completed' do
        expect(presenter.completed_issues).to eq(0)
      end

      it 'returns 0 for total' do
        expect(presenter.total_issues).to eq(0)
      end
    end
  end

  describe '#issues_display' do
    it 'formats as completed/total' do
      expect(presenter.issues_display).to eq('20/25')
    end
  end

  describe '#bug_count' do
    it 'returns the bug count' do
      expect(presenter.bug_count).to eq(3)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.bug_count).to eq(0)
      end
    end
  end

  describe '#assignee_count' do
    it 'returns the assignee count' do
      expect(presenter.assignee_count).to eq(8)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.assignee_count).to eq(0)
      end
    end
  end

  describe '#velocity' do
    it 'returns the velocity' do
      expect(presenter.velocity).to eq(42)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.velocity).to eq(0)
      end
    end
  end

  describe '#velocity_display' do
    it 'formats velocity with pts suffix' do
      expect(presenter.velocity_display).to eq('42 pts')
    end
  end

  describe '#tickets_per_day' do
    it 'returns tickets per day' do
      expect(presenter.tickets_per_day).to eq(1.43)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.tickets_per_day).to eq(0)
      end
    end
  end

  describe '#completion_rate' do
    it 'returns the completion rate' do
      expect(presenter.completion_rate).to eq(80.0)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.completion_rate).to eq(0)
      end
    end
  end

  describe '#completion_rate_display' do
    it 'formats with percentage unit' do
      expect(presenter.completion_rate_display).to eq('80.0%')
    end
  end

  describe '#carryover' do
    it 'returns the carryover count' do
      expect(presenter.carryover).to eq(2)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.carryover).to eq(0)
      end
    end
  end

  describe '#scope_change' do
    it 'returns the scope change value' do
      expect(presenter.scope_change).to eq(15.5)
    end

    context 'when nil' do
      let(:cycle) { { name: 'Cycle 1' } }

      it 'returns 0' do
        expect(presenter.scope_change).to eq(0)
      end
    end
  end

  describe '#scope_change_display' do
    context 'with positive scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: 15.5 } }

      it 'includes plus sign' do
        expect(presenter.scope_change_display).to eq('+15.5%')
      end
    end

    context 'with negative scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: -10.0 } }

      it 'includes minus sign from value' do
        expect(presenter.scope_change_display).to eq('-10.0%')
      end
    end

    context 'with zero scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: 0 } }

      it 'has no sign' do
        expect(presenter.scope_change_display).to eq('0%')
      end
    end
  end

  describe '#scope_change_tooltip' do
    it 'shows initial and final scope' do
      expect(presenter.scope_change_tooltip).to eq('Initial: 20 issues → Final: 23 issues')
    end
  end

  describe '#scope_change_class' do
    context 'with negative scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: -5.0 } }

      it 'returns scope-decreased' do
        expect(presenter.scope_change_class).to eq('scope-decreased')
      end
    end

    context 'with zero scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: 0 } }

      it 'returns scope-neutral' do
        expect(presenter.scope_change_class).to eq('scope-neutral')
      end
    end

    context 'with positive scope change' do
      let(:cycle) { { name: 'Cycle 1', scope_change: 10.0 } }

      it 'returns scope-increased' do
        expect(presenter.scope_change_class).to eq('scope-increased')
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash with all presenter data' do
      result = presenter.to_h
      expect(result).to be_a(Hash)
      expect(result).to include(
        name: 'Cycle 10',
        status: 'active',
        status_class: 'status-active',
        progress: 75.5,
        completed_issues: 20,
        total_issues: 25,
        issues_display: '20/25',
        bug_count: 3,
        assignee_count: 8,
        velocity: 42,
        velocity_display: '42 pts',
        tickets_per_day: 1.43,
        completion_rate: 80.0,
        completion_rate_display: '80.0%',
        carryover: 2,
        scope_change: 15.5,
        scope_change_display: '+15.5%',
        scope_change_class: 'scope-increased'
      )
    end
  end
end
