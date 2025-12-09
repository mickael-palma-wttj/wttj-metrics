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
end
