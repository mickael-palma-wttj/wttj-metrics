# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Services::Github::DataFetcher do
  subject(:fetcher) { described_class.new(logger) }

  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:client) { instance_double(WttjMetrics::Sources::Github::Client) }
  let(:prs) { [{ 'title' => 'PR 1', 'createdAt' => Date.today.iso8601, 'url' => 'http://github.com/owner/repo/pull/1' }] }

  before do
    allow(WttjMetrics::Sources::Github::Client).to receive(:new).and_return(client)
    allow(client).to receive(:fetch_pull_requests).and_return(prs)
    ENV['GITHUB_REPO'] = 'owner/repo'
    ENV.delete('GITHUB_ORG')
  end

  after do
    ENV.delete('GITHUB_REPO')
    ENV.delete('GITHUB_ORG')
  end

  describe '#call' do
    before do
      allow(WttjMetrics::Data::FileCache).to receive(:new).and_return(instance_double(WttjMetrics::Data::FileCache,
                                                                                      read: nil, write: nil))
    end

    it 'fetches pull requests' do
      allow(client).to receive(:fetch_pull_requests).and_return(prs)
      result = fetcher.call
      expected_prs = [{ title: 'PR 1', createdAt: Date.today.iso8601, url: 'http://github.com/owner/repo/pull/1' }]
      expect(result[:pull_requests]).to eq(expected_prs)
    end

    context 'when GITHUB_REPO is missing' do
      before do
        ENV.delete('GITHUB_REPO')
        ENV.delete('GITHUB_ORG')
      end

      it 'returns empty hash and logs error' do
        result = fetcher.call
        expect(result).to eq({})
        expect(logger).to have_received(:error).with(/GITHUB_ORG or GITHUB_REPO environment variable is not set/)
      end
    end

    context 'when GITHUB_ORG is set' do
      before do
        ENV.delete('GITHUB_REPO')
        ENV['GITHUB_ORG'] = 'my-org'
        allow(client).to receive(:fetch_organization_pull_requests).and_return(prs)
      end

      after { ENV.delete('GITHUB_ORG') }

      it 'fetches organization pull requests' do
        result = fetcher.call
        expected_prs = [{ title: 'PR 1', createdAt: Date.today.iso8601, url: 'http://github.com/owner/repo/pull/1' }]
        expect(result[:pull_requests]).to eq(expected_prs)
        expect(client).to have_received(:fetch_organization_pull_requests).with('my-org', anything)
      end
    end

    context 'with custom days' do
      subject(:fetcher) { described_class.new(logger, 30) }

      it 'fetches pull requests from 30 days ago' do
        fetcher.call
        expected_date = (Date.today - 30).iso8601
        expect(client).to have_received(:fetch_pull_requests).with('owner/repo', expected_date)
      end
    end
  end
end
