# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Sources::Github::Client do
  subject(:client) { described_class.new }

  let(:octokit) { instance_double(Octokit::Client) }
  let(:page_info) { double(hasNextPage: false, endCursor: nil) }
  let(:response) { double(data: double(repository: double(pullRequests: double(nodes: [], pageInfo: page_info)))) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(octokit)
    allow(octokit).to receive(:post).and_return(response)
  end

  describe '#fetch_pull_requests' do
    it 'fetches pull requests via GraphQL' do
      client.fetch_pull_requests('owner/repo', '2024-01-01')
      expect(octokit).to have_received(:post).with('/graphql', anything)
    end
  end

  describe '#fetch_organization_pull_requests' do
    let(:search_data) { double(nodes: [], pageInfo: page_info, issueCount: 500) }
    let(:response) { double(data: double(search: search_data)) }

    it 'fetches organization pull requests via GraphQL' do
      client.fetch_organization_pull_requests('org', '2024-01-01')

      expect(octokit).to have_received(:post).at_least(:once) do |path, body_json|
        expect(path).to eq('/graphql')
        body = JSON.parse(body_json)
        expect(body['variables']['query']).to include('org:org')
      end
    end
  end

  describe 'error handling' do
    let(:logger) { instance_double(Logger, warn: nil, error: nil) }
    subject(:client) { described_class.new(logger: logger) }

    context 'when rate limit is exceeded' do
      let(:headers) { { 'retry-after' => '1' } }
      let(:error) do
        e = Octokit::TooManyRequests.new
        allow(e).to receive(:response_headers).and_return(headers)
        e
      end

      before do
        allow(client).to receive(:sleep)
        call_count = 0
        allow(octokit).to receive(:post) do
          call_count += 1
          raise error if call_count == 1
          response
        end
      end

      it 'retries after sleeping' do
        client.fetch_pull_requests('owner/repo', '2024-01-01')
        expect(client).to have_received(:sleep).with(1)
        expect(octokit).to have_received(:post).twice
      end
    end

    context 'when server error occurs' do
      let(:error) { Octokit::BadGateway.new }

      before do
        allow(client).to receive(:sleep)
        call_count = 0
        allow(octokit).to receive(:post) do
          call_count += 1
          raise error if call_count <= 2
          response
        end
      end

      it 'retries with exponential backoff' do
        client.fetch_pull_requests('owner/repo', '2024-01-01')
        expect(octokit).to have_received(:post).exactly(3).times
        expect(client).to have_received(:sleep).with(2)
        expect(client).to have_received(:sleep).with(4)
      end
    end

    context 'when max retries exceeded' do
      let(:error) { Octokit::BadGateway.new }

      before do
        allow(client).to receive(:sleep)
        allow(octokit).to receive(:post).and_raise(error)
      end

      it 'raises error after retries' do
        expect {
          client.fetch_pull_requests('owner/repo', '2024-01-01')
        }.to raise_error(Octokit::BadGateway)
        expect(octokit).to have_received(:post).exactly(4).times
      end
    end
  end
end
