# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Services::TeamMatcher do
  subject(:matcher) { described_class.new(available_teams) }

  let(:available_teams) { ['Team A', 'Team B', 'Other Team'] }

  describe '#match' do
    it 'matches exact name' do
      expect(matcher.match('Team A')).to contain_exactly('Team A')
    end

    it 'matches case insensitively' do
      expect(matcher.match('team a')).to contain_exactly('Team A')
    end

    it 'matches with glob pattern' do
      expect(matcher.match('Team *')).to contain_exactly('Team A', 'Team B')
    end

    it 'matches multiple patterns' do
      expect(matcher.match(['Team A', 'Other *'])).to contain_exactly('Team A', 'Other Team')
    end

    it 'returns unique matches' do
      expect(matcher.match(['Team A', 'Team *'])).to contain_exactly('Team A', 'Team B')
    end

    it 'returns empty array if no match' do
      expect(matcher.match('NonExistent')).to be_empty
    end

    it 'handles single pattern as string' do
      expect(matcher.match('Team A')).to be_a(Array)
    end
  end
end
