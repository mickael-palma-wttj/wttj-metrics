# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Metrics::Github::ContributorActivityCalculator do
  subject(:calculator) { described_class.new(pull_requests) }

  let(:pull_requests) do
    [
      { 'createdAt' => '2024-01-01T10:00:00Z', 'author' => { 'login' => 'user1' } },
      { 'createdAt' => '2024-01-01T12:00:00Z', 'author' => { 'login' => 'user1' } },
      { 'createdAt' => '2024-01-02T10:00:00Z', 'author' => { 'login' => 'user2' } }
    ]
  end

  describe '#calculate' do
    it 'counts PRs per user per day' do
      result = calculator.calculate
      expect(result).to include(
        %w[2024-01-01 user1] => 2,
        %w[2024-01-02 user2] => 1
      )
    end
  end

  describe '#to_rows' do
    it 'formats result as rows' do
      rows = calculator.to_rows
      expect(rows).to include(
        ['2024-01-01', 'github_contributor_activity', 'user1', 2],
        ['2024-01-02', 'github_contributor_activity', 'user2', 1]
      )
    end

    context 'with category' do
      it 'uses custom category' do
        rows = calculator.to_rows('custom')
        expect(rows.first[1]).to eq('custom_contributor_activity')
      end
    end

    context 'with symbol keys' do
      let(:pull_requests) do
        [
          { createdAt: '2024-01-01T10:00:00Z', author: { login: 'user1' } }
        ]
      end

      it 'handles symbol keys' do
        rows = calculator.to_rows
        expect(rows).to include(['2024-01-01', 'github_contributor_activity', 'user1', 1])
      end
    end

    context 'with missing author' do
      let(:pull_requests) do
        [
          { 'createdAt' => '2024-01-01T10:00:00Z' }
        ]
      end

      it 'uses unknown author' do
        rows = calculator.to_rows
        expect(rows.first[2]).to eq('unknown')
      end
    end
  end
end
