# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Metrics::Github::RepositoryActivityCalculator do
  subject(:calculator) { described_class.new(pull_requests) }

  let(:date) { Date.today.to_s }
  let(:pull_requests) do
    [
      { 'repository' => { 'name' => 'repo-a' }, 'createdAt' => date },
      { 'repository' => { 'name' => 'repo-a' }, 'createdAt' => date },
      { 'repository' => { 'name' => 'repo-b' }, 'createdAt' => date },
      { 'repository' => { 'name' => 'repo-c' }, 'createdAt' => date }
    ]
  end

  describe '#to_rows' do
    it 'returns PR counts per repository' do
      rows = calculator.to_rows

      expect(rows).to contain_exactly(
        [date, 'github_repo_activity', 'repo-a', 2],
        [date, 'github_repo_activity', 'repo-b', 1],
        [date, 'github_repo_activity', 'repo-c', 1]
      )
    end

    context 'with missing repository info' do
      let(:pull_requests) do
        [
          { 'repository' => { 'name' => 'repo-a' }, 'createdAt' => date },
          { 'other_field' => 'value', 'createdAt' => date }
        ]
      end

      it 'handles missing repository gracefully' do
        rows = calculator.to_rows
        expect(rows).to include(
          [date, 'github_repo_activity', 'repo-a', 1]
        )
        # nil key might be present if dig returns nil
        expect(rows).to include(
          [date, 'github_repo_activity', 'unknown', 1]
        )
      end
    end
  end
end
