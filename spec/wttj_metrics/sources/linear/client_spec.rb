# frozen_string_literal: true

RSpec.describe WttjMetrics::Sources::Linear::Client do
  subject(:client) { described_class.new(api_key) }

  # Setup
  let(:api_key) { ENV['LINEAR_API_KEY'] || 'test_api_key' }
  let(:api_url) { 'https://api.linear.app/graphql' }

  before do
    allow(WttjMetrics::Config).to receive(:linear_api_url).and_return(api_url)
  end

  describe '#query' do
    subject(:query_result) { client.query(graphql_query) }

    # Setup
    let(:graphql_query) { '{ viewer { id } }' }

    context 'with successful response' do
      before do
        stub_request(:post, api_url)
          .with(
            headers: {
              'Authorization' => api_key,
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { data: { viewer: { id: '123' } } }.to_json
          )
      end

      it 'returns parsed JSON response' do
        expect(query_result).to eq({ 'data' => { 'viewer' => { 'id' => '123' } } })
      end
    end

    context 'with API failure' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 401, body: 'Unauthorized')
      end

      it 'raises an error' do
        expect { query_result }.to raise_error(WttjMetrics::Error, /Linear API Error/)
      end
    end
  end

  describe '#fetch_all_issues', :vcr do
    subject(:issues) { client.fetch_all_issues }

    it 'fetches all pages and returns combined results', :aggregate_failures do
      expect(issues.size).to eq(2)
      expect(issues.map { |i| i['id'] }).to eq(%w[1 2])
    end
  end

  describe '#fetch_cycles', :vcr do
    subject(:cycles) { client.fetch_cycles }

    it 'returns all cycles', :aggregate_failures do
      expect(cycles.size).to eq(2)
      expect(cycles.first['name']).to eq('Sprint 1')
    end
  end

  describe '#fetch_workflow_states', :vcr do
    subject(:states) { client.fetch_workflow_states }

    it 'returns all workflow states', :aggregate_failures do
      expect(states.size).to eq(2)
      expect(states.map { |s| s['name'] }).to eq(['Backlog', 'In Progress'])
    end
  end

  describe 'caching behavior' do
    subject(:client_with_cache) { described_class.new(api_key, cache: cache) }

    # Setup
    let(:cache) { {} }

    context 'when cache is pre-populated' do
      before do
        cache['cycles_all'] = [{ 'id' => 'cached' }]
      end

      it 'returns cached value without API call' do
        result = client_with_cache.fetch_cycles

        expect(result).to eq([{ 'id' => 'cached' }])
      end
    end

    context 'when cache is empty', :vcr do
      it 'makes API call and returns result' do
        result = client_with_cache.fetch_cycles

        expect(result).to eq([{ 'id' => 'c1', 'name' => 'Sprint 1', 'number' => 1 },
                              { 'id' => 'c2', 'name' => 'Sprint 2', 'number' => 2 }])
      end
    end
  end
end
