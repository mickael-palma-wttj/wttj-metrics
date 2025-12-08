# frozen_string_literal: true

require 'logger'

RSpec.describe WttjMetrics::Services::DataFetcher do
  let(:cache) { instance_double(WttjMetrics::Data::FileCache) }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:client) { instance_double(WttjMetrics::Sources::Linear::Client) }

  let(:mock_issues) do
    [
      { id: '1', title: 'Issue 1' },
      { id: '2', title: 'Issue 2' }
    ]
  end

  let(:mock_cycles) do
    [
      { id: 'c1', name: 'Sprint 1' },
      { id: 'c2', name: 'Sprint 2' }
    ]
  end

  let(:mock_team_members) do
    [
      { id: 'm1', name: 'Alice' },
      { id: 'm2', name: 'Bob' }
    ]
  end

  let(:mock_workflow_states) do
    [
      { id: 's1', name: 'To Do' },
      { id: 's2', name: 'In Progress' }
    ]
  end

  before do
    allow(WttjMetrics::Sources::Linear::Client).to receive(:new)
      .with(cache: cache)
      .and_return(client)

    allow(client).to receive_messages(
      fetch_all_issues: mock_issues,
      fetch_cycles: mock_cycles,
      fetch_team_members: mock_team_members,
      fetch_workflow_states: mock_workflow_states
    )
  end

  describe '#call' do
    subject(:fetcher) { described_class.new(cache, logger) }

    it 'logs the start of data fetching' do
      fetcher.call

      expect(logger).to have_received(:info).with('📊 Fetching data from Linear...')
    end

    it 'creates a Linear client with the provided cache' do
      fetcher.call

      expect(WttjMetrics::Sources::Linear::Client).to have_received(:new).with(cache: cache)
    end

    it 'fetches all issues from the client' do
      fetcher.call

      expect(client).to have_received(:fetch_all_issues)
    end

    it 'fetches cycles from the client' do
      fetcher.call

      expect(client).to have_received(:fetch_cycles)
    end

    it 'fetches team members from the client' do
      fetcher.call

      expect(client).to have_received(:fetch_team_members)
    end

    it 'fetches workflow states from the client' do
      fetcher.call

      expect(client).to have_received(:fetch_workflow_states)
    end

    it 'logs the count of issues and cycles' do
      fetcher.call

      expect(logger).to have_received(:info).with('   Found 2 issues')
      expect(logger).to have_received(:info).with('   Found 2 cycles')
    end

    it 'returns a hash with all fetched data' do
      result = fetcher.call

      expect(result).to eq(
        issues: mock_issues,
        cycles: mock_cycles,
        team_members: mock_team_members,
        workflow_states: mock_workflow_states
      )
    end

    it 'returns the correct structure with keys' do
      result = fetcher.call

      expect(result.keys).to contain_exactly(:issues, :cycles, :team_members, :workflow_states)
    end

    context 'with empty results' do
      let(:mock_issues) { [] }
      let(:mock_cycles) { [] }

      it 'logs zero counts' do
        fetcher.call

        expect(logger).to have_received(:info).with('   Found 0 issues')
        expect(logger).to have_received(:info).with('   Found 0 cycles')
      end

      it 'returns empty arrays' do
        result = fetcher.call

        expect(result[:issues]).to eq([])
        expect(result[:cycles]).to eq([])
      end
    end

    context 'with large datasets' do
      let(:mock_issues) { Array.new(1500) { |i| { id: i.to_s, title: "Issue #{i}" } } }
      let(:mock_cycles) { Array.new(50) { |i| { id: i.to_s, name: "Sprint #{i}" } } }

      it 'logs correct counts for large datasets' do
        fetcher.call

        expect(logger).to have_received(:info).with('   Found 1500 issues')
        expect(logger).to have_received(:info).with('   Found 50 cycles')
      end
    end
  end
end
