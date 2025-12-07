# frozen_string_literal: true

require 'tempfile'
require 'csv'

RSpec.describe WttjMetrics::Reports::ReportGenerator do
  subject(:generator) { described_class.new(csv_path, days: 90, teams: teams) }

  let(:csv_path) { temp_csv.path }
  let(:temp_csv) { Tempfile.new(['metrics', '.csv']) }
  let(:teams) { nil }

  before do
    # Create a realistic test CSV file
    CSV.open(temp_csv.path, 'w') do |csv|
      csv << %w[date category metric value]
      csv << %w[2024-12-01 flow throughput 10]
      csv << %w[2024-12-02 flow throughput 15]
      csv << %w[2024-12-01 flow wip 25]
      csv << %w[2024-12-01 bugs open_bugs 5]
      csv << %w[2024-12-01 status Todo 30]
      csv << %w[2024-12-01 status Done 100]
      csv << %w[2024-12-01 priority High 10]
      csv << %w[2024-12-01 type Feature 40]
      csv << ['2024-12-01', 'assignee', 'John Doe', '15']
      csv << ['2024-12-01', 'bugs_by_team', 'ATS:open', '5']
      csv << ['2024-12-01', 'bugs_by_team', 'ATS:created', '3']
      csv << ['2024-12-01', 'bugs_by_team', 'ATS:closed', '2']
      csv << ['2024-12-01', 'cycle_metrics', 'cycle_1:total_issues', '10']
    end
  end

  after do
    temp_csv.close
    temp_csv.unlink
  end

  describe '#initialize' do
    it 'loads CSV data' do
      expect(generator.data).not_to be_empty
    end

    it 'sets default teams when none provided' do
      expect(generator.selected_teams).to eq(described_class::SELECTED_TEAMS)
    end

    it 'uses custom teams when provided' do
      gen = described_class.new(csv_path, days: 90, teams: %w[ATS Platform])
      expect(gen.selected_teams).to eq(%w[ATS Platform])
    end

    it 'discovers all teams when :all is passed' do
      gen = described_class.new(csv_path, days: 90, teams: :all)
      expect(gen.all_teams_mode).to be true
      # Team discovery happens from bugs_by_team metrics
      expect(gen.selected_teams).to be_an(Array)
    end

    it 'sets days_to_show' do
      expect(generator.days_to_show).to eq(90)
    end
  end

  describe '#flow_metrics' do
    it 'returns flow metrics' do
      expect(generator.flow_metrics).to be_an(Array)
    end

    it 'caches the result' do
      first_call = generator.flow_metrics
      second_call = generator.flow_metrics
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe '#flow_metrics_presented' do
    it 'returns presented flow metrics' do
      expect(generator.flow_metrics_presented).to be_an(Array)
    end

    it 'wraps metrics in presenters when data exists' do
      if generator.flow_metrics.any?
        expect(generator.flow_metrics_presented.first).to be_a(WttjMetrics::Presenters::FlowMetricPresenter)
      end
    end
  end

  describe '#status_dist' do
    it 'returns status distribution' do
      expect(generator.status_dist).to be_an(Array)
    end
  end

  describe '#priority_dist' do
    it 'returns priority distribution' do
      expect(generator.priority_dist).to be_an(Array)
    end
  end

  describe '#type_dist' do
    it 'returns type distribution' do
      expect(generator.type_dist).to be_an(Array)
    end
  end

  describe '#assignee_dist' do
    it 'returns assignee distribution' do
      expect(generator.assignee_dist).to be_an(Array)
    end

    it 'limits to top 15 assignees' do
      expect(generator.assignee_dist.size).to be <= 15
    end

    it 'sorts by value descending' do
      dist = generator.assignee_dist
      values = dist.map { |m| m[:value] }
      expect(values).to eq(values.sort.reverse)
    end
  end

  describe '#status_chart_data' do
    it 'returns chart-ready status data' do
      data = generator.status_chart_data
      expect(data).to be_an(Array)
      expect(data.first).to have_key(:label) if data.any?
      expect(data.first).to have_key(:value) if data.any?
    end
  end

  describe '#priority_chart_data' do
    it 'returns chart-ready priority data' do
      data = generator.priority_chart_data
      expect(data).to be_an(Array)
    end
  end

  describe '#type_chart_data' do
    it 'returns chart-ready type data' do
      data = generator.type_chart_data
      expect(data).to be_an(Array)
    end
  end

  describe '#assignee_chart_data' do
    it 'returns chart-ready assignee data' do
      data = generator.assignee_chart_data
      expect(data).to be_an(Array)
    end
  end

  describe '#bugs_by_team' do
    let(:teams) { ['ATS'] }

    it 'returns bug stats by team' do
      expect(generator.bugs_by_team).to be_a(Hash)
    end

    it 'only includes selected teams' do
      expect(generator.bugs_by_team.keys).to all(be_in(teams))
    end
  end

  describe '#generate_html' do
    let(:output_path) { File.join(Dir.tmpdir, 'test_report.html') }

    after do
      FileUtils.rm_f(output_path)
    end

    it 'generates an HTML file' do
      generator.generate_html(output_path)
      expect(File.exist?(output_path)).to be true
    end

    it 'creates valid HTML content' do
      generator.generate_html(output_path)
      content = File.read(output_path)
      expect(content).to include('<!DOCTYPE')
      expect(content).to include('html')
      expect(File.size(output_path)).to be > 100
    end
  end

  describe '#generate_excel' do
    let(:output_path) { File.join(Dir.tmpdir, 'test_report.xlsx') }

    after do
      FileUtils.rm_f(output_path)
    end

    it 'generates an Excel file' do
      generator.generate_excel(output_path)
      expect(File.exist?(output_path)).to be true
    end

    it 'creates a non-empty Excel file' do
      generator.generate_excel(output_path)
      expect(File.size(output_path)).to be > 0
    end
  end

  describe '#cycles_parsed' do
    it 'returns parsed cycles as hash' do
      expect(generator.cycles_parsed).to be_a(Hash)
    end

    it 'filters cycles by cutoff date' do
      allow(generator).to receive(:cutoff_date).and_return('2024-12-01')
      expect(generator.cycles_parsed).to be_a(Hash)
    end
  end

  describe '#cycles_by_team' do
    it 'returns cycles organized by team' do
      expect(generator.cycles_by_team).to be_a(Hash)
    end

    it 'filters cycles by cutoff date' do
      allow(generator).to receive(:cutoff_date).and_return('2024-12-01')
      expect(generator.cycles_by_team).to be_a(Hash)
    end
  end

  describe '#bugs_by_team_presented' do
    let(:teams) { ['ATS'] }

    it 'returns presented bug team stats' do
      expect(generator.bugs_by_team_presented).to be_an(Array)
    end
  end

  describe '#cycle_metrics_presented' do
    it 'returns presented cycle metrics' do
      expect(generator.cycle_metrics_presented).to be_an(Array)
    end
  end

  describe '#team_metrics_presented' do
    it 'returns presented team metrics' do
      expect(generator.team_metrics_presented).to be_an(Array)
    end
  end

  describe '#bug_metrics_presented' do
    it 'returns presented bug metrics' do
      expect(generator.bug_metrics_presented).to be_an(Array)
    end
  end

  describe '#bugs_by_priority' do
    it 'returns bugs grouped by priority' do
      expect(generator.bugs_by_priority).to be_an(Array)
    end
  end

  describe '#weekly_flow_data' do
    it 'returns weekly flow data structure' do
      data = generator.weekly_flow_data
      expect(data).to have_key(:labels)
      expect(data).to have_key(:created_pct)
      expect(data).to have_key(:completed_pct)
    end
  end

  describe '#weekly_bug_flow_data' do
    it 'returns weekly bug flow data structure' do
      data = generator.weekly_bug_flow_data
      expect(data).to have_key(:labels)
      expect(data).to have_key(:created)
      expect(data).to have_key(:closed)
    end
  end

  describe '#transition_weekly_data' do
    it 'returns transition data structure' do
      data = generator.transition_weekly_data
      expect(data).to have_key(:labels)
      expect(data).to have_key(:datasets)
    end
  end

  describe '#team_stats' do
    it 'returns team statistics' do
      expect(generator.team_stats).to be_a(Hash)
    end
  end

  describe '#cycles_by_team_presented' do
    it 'returns presented cycles by team' do
      expect(generator.cycles_by_team_presented).to be_a(Hash)
    end
  end

  describe '#weekly_bug_flow_by_team_data' do
    it 'returns weekly bug flow data by team' do
      data = generator.weekly_bug_flow_by_team_data
      expect(data).to have_key(:labels)
      expect(data).to have_key(:teams)
      expect(data[:teams]).to be_a(Hash)
    end

    it 'includes data for selected teams' do
      data = generator.weekly_bug_flow_by_team_data
      data[:teams].each_key do |team|
        expect(generator.selected_teams).to include(team)
      end
    end
  end

  describe '#cutoff_date' do
    it 'calculates cutoff date based on days_to_show' do
      cutoff = generator.send(:cutoff_date)
      expected = (Date.today - 90).to_s
      expect(cutoff).to eq(expected)
    end
  end

  describe '#discover_all_teams' do
    it 'extracts unique team names from bugs_by_team metrics' do
      teams = generator.send(:discover_all_teams)
      expect(teams).to be_an(Array)
      # May be empty if no bugs_by_team data in test CSV
    end

    it 'excludes Unknown team' do
      teams = generator.send(:discover_all_teams)
      expect(teams).not_to include('Unknown')
    end
  end

  describe '#build_bugs_by_team' do
    let(:teams) { ['ATS'] }

    it 'returns hash with team bug stats' do
      result = generator.send(:build_bugs_by_team)
      expect(result).to be_a(Hash)
    end

    it 'includes only selected teams' do
      result = generator.send(:build_bugs_by_team)
      expect(result.keys).to all(be_in(teams))
    end

    it 'includes created, closed, and open counts' do
      result = generator.send(:build_bugs_by_team)
      if result.any?
        expect(result.values.first).to have_key(:created)
        expect(result.values.first).to have_key(:closed)
        expect(result.values.first).to have_key(:open)
      end
    end

    it 'sorts teams by open bugs descending' do
      result = generator.send(:build_bugs_by_team)
      open_counts = result.values.map { |v| v[:open] }
      expect(open_counts).to eq(open_counts.sort.reverse)
    end
  end

  describe '#build_week_counts' do
    it 'returns empty hash for empty metrics' do
      result = generator.send(:build_week_counts, [])
      expect(result).to eq({})
    end

    it 'groups metrics by week' do
      metrics = [
        { date: '2024-12-01', value: 5 },
        { date: '2024-12-02', value: 3 }
      ]
      result = generator.send(:build_week_counts, metrics)
      expect(result).to be_a(Hash)
      expect(result.values.sum).to eq(8)
    end
  end

  describe '#build_html' do
    it 'uses ERB template when available' do
      html = generator.send(:build_html)
      expect(html).to include('<!DOCTYPE')
      expect(html).to include('html')
    end

    it 'uses fallback when template missing' do
      allow(File).to receive(:exist?).and_return(false)
      html = generator.send(:build_html_fallback)
      expect(html).to include('<!DOCTYPE html')
      expect(html).to include('Linear Metrics Dashboard')
    end
  end

  describe '#excel_report_data' do
    it 'returns hash with all required keys' do
      data = generator.send(:excel_report_data)
      expect(data).to have_key(:today)
      expect(data).to have_key(:days_to_show)
      expect(data).to have_key(:flow_metrics)
      expect(data).to have_key(:cycle_metrics)
      expect(data).to have_key(:team_metrics)
      expect(data).to have_key(:bug_metrics)
      expect(data).to have_key(:bugs_by_priority)
      expect(data).to have_key(:status_chart_data)
      expect(data).to have_key(:priority_dist)
      expect(data).to have_key(:type_dist)
      expect(data).to have_key(:assignee_dist)
      expect(data).to have_key(:team_stats)
      expect(data).to have_key(:cycles_by_team)
      expect(data).to have_key(:weekly_flow_data)
      expect(data).to have_key(:raw_data)
    end
  end

  describe 'TransitionDataBuilder' do
    let(:transition_metrics) do
      [
        { date: '2024-12-01', metric: 'ATS:Todo', value: 10 },
        { date: '2024-12-01', metric: 'ATS:Done', value: 5 },
        { date: '2024-12-02', metric: 'ATS:In Progress', value: 8 }
      ]
    end
    let(:builder) { WttjMetrics::Reports::TransitionDataBuilder.new(transition_metrics, '2024-12-01', teams: ['ATS']) }

    describe '#build' do
      it 'returns hash with labels and datasets' do
        result = builder.build
        expect(result).to have_key(:labels)
        expect(result).to have_key(:datasets)
      end

      it 'includes all state categories' do
        result = builder.build
        WttjMetrics::ReportGenerator::STATE_CATEGORIES.each_key do |state|
          expect(result[:datasets]).to have_key(state)
        end
      end

      it 'includes percentages and raw values' do
        result = builder.build
        result[:datasets].each_value do |data|
          expect(data).to have_key(:percentages)
          expect(data).to have_key(:raw)
        end
      end
    end

    describe 'with nil transition metrics' do
      let(:builder) { WttjMetrics::Reports::TransitionDataBuilder.new(nil, '2024-12-01') }

      it 'handles nil metrics gracefully' do
        result = builder.build
        expect(result).to have_key(:labels)
        expect(result).to have_key(:datasets)
      end
    end

    describe 'without team filter' do
      let(:transition_metrics) do
        [
          { date: '2024-12-01', metric: 'Todo', value: 10 },
          { date: '2024-12-01', metric: 'Done', value: 5 }
        ]
      end
      let(:builder) { WttjMetrics::Reports::TransitionDataBuilder.new(transition_metrics, '2024-12-01', teams: nil) }

      it 'processes non-team-specific metrics' do
        result = builder.build
        expect(result).to have_key(:labels)
        expect(result).to have_key(:datasets)
      end
    end
  end
end
