# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Github::TeamService do
  subject(:service) { described_class.new(parser, config) }

  let(:parser) { instance_double(WttjMetrics::Data::CsvParser, metrics_by_category: metrics_by_category) }
  let(:config) { nil }
  let(:metrics_by_category) do
    {
      'github:TeamA' => [],
      'github:TeamB' => [],
      'github:TeamA_daily' => [],
      'linear:TeamC' => []
    }
  end

  describe '#resolve_teams' do
    context 'without config' do
      it 'returns all available github teams excluding special suffixes' do
        expect(service.resolve_teams).to contain_exactly('TeamA', 'TeamB')
      end
    end

    context 'with config' do
      let(:config) { instance_double(WttjMetrics::Values::TeamConfiguration, defined_teams: ['UnifiedTeam']) }
      let(:matcher) { instance_double(WttjMetrics::Services::TeamMatcher, match: ['TeamA']) }

      before do
        allow(config).to receive(:patterns_for).with('UnifiedTeam', :github).and_return(['TeamA'])
        allow(WttjMetrics::Services::TeamMatcher).to receive(:new).and_return(matcher)
      end

      it 'filters teams based on config' do
        expect(service.resolve_teams).to contain_exactly('TeamA')
      end
    end
  end
end
