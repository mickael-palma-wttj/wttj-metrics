# frozen_string_literal: true

RSpec.describe WttjMetrics::Presenters::BugTeamPresenter do
  subject(:presenter) { described_class.new(team, stats) }

  let(:team) { 'Platform' }

  describe '#name' do
    let(:stats) { { created: 10, closed: 8, open: 2 } }

    it 'returns the team name' do
      expect(presenter.name).to eq('Platform')
    end
  end

  describe '#created' do
    let(:stats) { { created: 15, closed: 10, open: 5 } }

    it 'returns the number of created bugs' do
      expect(presenter.created).to eq(15)
    end
  end

  describe '#closed' do
    let(:stats) { { created: 15, closed: 10, open: 5 } }

    it 'returns the number of closed bugs' do
      expect(presenter.closed).to eq(10)
    end
  end

  describe '#open' do
    let(:stats) { { created: 15, closed: 10, open: 5 } }

    it 'returns the number of open bugs' do
      expect(presenter.open).to eq(5)
    end
  end

  describe '#resolution_rate' do
    context 'with bugs created and closed' do
      let(:stats) { { created: 10, closed: 8, open: 2 } }

      it 'calculates resolution rate as percentage' do
        expect(presenter.resolution_rate).to eq(80.0)
      end
    end

    context 'with all bugs closed' do
      let(:stats) { { created: 10, closed: 10, open: 0 } }

      it 'returns 100%' do
        expect(presenter.resolution_rate).to eq(100.0)
      end
    end

    context 'with no bugs closed' do
      let(:stats) { { created: 10, closed: 0, open: 10 } }

      it 'returns 0%' do
        expect(presenter.resolution_rate).to eq(0.0)
      end
    end

    context 'with no bugs created' do
      let(:stats) { { created: 0, closed: 0, open: 0 } }

      it 'returns 0' do
        expect(presenter.resolution_rate).to eq(0)
      end
    end

    context 'with partial closure' do
      let(:stats) { { created: 3, closed: 1, open: 2 } }

      it 'calculates correct percentage' do
        expect(presenter.resolution_rate).to eq(33.3)
      end
    end
  end

  describe '#resolution_rate_display' do
    let(:stats) { { created: 10, closed: 8, open: 2 } }

    it 'formats resolution rate with percentage symbol' do
      expect(presenter.resolution_rate_display).to eq('80.0%')
    end
  end

  describe '#resolution_rate_class' do
    context 'with high resolution rate (>= 80%)' do
      let(:stats) { { created: 10, closed: 9, open: 1 } }

      it 'returns status-active class' do
        expect(presenter.resolution_rate_class).to eq('status-active')
      end
    end

    context 'with resolution rate at exactly 80%' do
      let(:stats) { { created: 10, closed: 8, open: 2 } }

      it 'returns status-active class' do
        expect(presenter.resolution_rate_class).to eq('status-active')
      end
    end

    context 'with medium resolution rate (50-79%)' do
      let(:stats) { { created: 10, closed: 6, open: 4 } }

      it 'returns status-upcoming class' do
        expect(presenter.resolution_rate_class).to eq('status-upcoming')
      end
    end

    context 'with resolution rate at exactly 50%' do
      let(:stats) { { created: 10, closed: 5, open: 5 } }

      it 'returns status-upcoming class' do
        expect(presenter.resolution_rate_class).to eq('status-upcoming')
      end
    end

    context 'with low resolution rate (< 50%)' do
      let(:stats) { { created: 10, closed: 3, open: 7 } }

      it 'returns status-past class' do
        expect(presenter.resolution_rate_class).to eq('status-past')
      end
    end

    context 'with no bugs created' do
      let(:stats) { { created: 0, closed: 0, open: 0 } }

      it 'returns status-past class' do
        expect(presenter.resolution_rate_class).to eq('status-past')
      end
    end
  end

  describe '#to_h' do
    let(:stats) { { created: 10, closed: 8, open: 2 } }

    it 'returns a hash with all presenter data' do
      result = presenter.to_h
      expect(result).to be_a(Hash)
      expect(result).to include(
        name: 'Platform',
        created: 10,
        closed: 8,
        open: 2,
        resolution_rate: 80.0,
        resolution_rate_display: '80.0%',
        resolution_rate_class: 'status-active'
      )
    end

    it 'contains all required keys' do
      result = presenter.to_h
      expect(result.keys).to contain_exactly(
        :name,
        :created,
        :closed,
        :open,
        :resolution_rate,
        :resolution_rate_display,
        :resolution_rate_class
      )
    end
  end
end
