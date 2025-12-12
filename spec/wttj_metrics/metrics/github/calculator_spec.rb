# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Metrics::Github::Calculator do
  subject(:calculator) { described_class.new(pull_requests, releases, teams) }

  let(:pull_requests) { [{ id: 1, author: { login: 'user1' } }] }
  let(:releases) { [] }
  let(:teams) { {} }

  let(:pr_velocity_calc) { instance_double(WttjMetrics::Metrics::Github::PrVelocityCalculator, to_rows: [['row1']]) }
  let(:collaboration_calc) { instance_double(WttjMetrics::Metrics::Github::CollaborationCalculator, to_rows: [['row2']]) }
  let(:timeseries_calc) { instance_double(WttjMetrics::Metrics::Github::TimeseriesCalculator, to_rows: [['row3']]) }
  let(:pr_size_calc) { instance_double(WttjMetrics::Metrics::Github::PrSizeCalculator, to_rows: [['row4']]) }
  let(:repo_activity_calc) { instance_double(WttjMetrics::Metrics::Github::RepositoryActivityCalculator, to_rows: [['row5']]) }
  let(:contrib_activity_calc) { instance_double(WttjMetrics::Metrics::Github::ContributorActivityCalculator, to_rows: [['row6']]) }
  let(:quality_calc) { instance_double(WttjMetrics::Metrics::Github::QualityCalculator, to_rows: [['row7']]) }

  before do
    allow(WttjMetrics::Metrics::Github::PrVelocityCalculator).to receive(:new).and_return(pr_velocity_calc)
    allow(WttjMetrics::Metrics::Github::CollaborationCalculator).to receive(:new).and_return(collaboration_calc)
    allow(WttjMetrics::Metrics::Github::TimeseriesCalculator).to receive(:new).and_return(timeseries_calc)
    allow(WttjMetrics::Metrics::Github::PrSizeCalculator).to receive(:new).and_return(pr_size_calc)
    allow(WttjMetrics::Metrics::Github::RepositoryActivityCalculator).to receive(:new).and_return(repo_activity_calc)
    allow(WttjMetrics::Metrics::Github::ContributorActivityCalculator)
      .to receive(:new).and_return(contrib_activity_calc)
    allow(WttjMetrics::Metrics::Github::QualityCalculator).to receive(:new).and_return(quality_calc)
  end

  describe '#calculate_all' do
    context 'without teams' do
      it 'calculates global metrics' do
        result = calculator.calculate_all
        expect(result).to contain_exactly(['row1'], ['row2'], ['row3'], ['row4'], ['row5'], ['row6'], ['row7'])
      end

      it 'initializes calculators with correct arguments' do
        calculator.calculate_all
        expect(WttjMetrics::Metrics::Github::PrVelocityCalculator).to have_received(:new).with(pull_requests)
        expect(pr_velocity_calc).to have_received(:to_rows).with('github')
        expect(timeseries_calc).to have_received(:to_rows).with('github_daily')
      end
    end

    context 'with teams' do
      let(:teams) { { 'TeamA' => ['user1'] } }

      it 'calculates global and team metrics' do
        result = calculator.calculate_all
        # 7 global + 7 team = 14 rows
        expect(result.size).to eq(14)
      end

      it 'filters PRs for team metrics' do
        calculator.calculate_all
        # Once for global, once for team
        expect(WttjMetrics::Metrics::Github::PrVelocityCalculator).to have_received(:new).twice
      end

      it 'passes correct category for team metrics' do
        calculator.calculate_all
        expect(pr_velocity_calc).to have_received(:to_rows).with('github:TeamA')
        expect(timeseries_calc).to have_received(:to_rows).with('github:TeamA_daily')
      end
    end

    context 'with nil inputs' do
      subject(:calculator) { described_class.new(pull_requests, nil, nil) }

      it 'handles nil releases and teams gracefully' do
        expect { calculator.calculate_all }.not_to raise_error
      end
    end
  end
end
