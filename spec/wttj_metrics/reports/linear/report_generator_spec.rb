# frozen_string_literal: true

require 'tempfile'
require 'csv'
require 'wttj_metrics/reports/linear/report_generator'

RSpec.describe WttjMetrics::Reports::Linear::ReportGenerator do
  subject(:generator) { described_class.new(csv_path, days: 90, teams: teams) }

  let(:csv_path) { temp_csv.path }
  let(:temp_csv) { Tempfile.new(['metrics', '.csv']) }
  let(:teams) { nil }

  before do
    # Create a realistic test CSV file
    today = Date.today.to_s
    CSV.open(temp_csv.path, 'w') do |csv|
      csv << %w[date category metric value]
      csv << [today, 'flow', 'throughput', '10']
      csv << [today, 'flow', 'throughput', '15'] # Duplicate metric for same day? Or maybe different day intended?
      csv << [today, 'flow', 'wip', '25']
      csv << [today, 'bugs', 'open_bugs', '5']
      csv << [today, 'status', 'Todo', '30']
      csv << [today, 'status', 'Done', '100']
      csv << [today, 'priority', 'High', '10']
      csv << [today, 'type', 'Feature', '40']
      csv << [today, 'assignee', 'John Doe', '15']
      csv << [today, 'bugs_by_team', 'ATS:open', '5']
      csv << [today, 'bugs_by_team', 'ATS:created', '3']
      csv << [today, 'bugs_by_team', 'ATS:closed', '2']
      csv << [today, 'cycle_metrics', 'cycle_1:total_issues', '10']
      csv << [today, 'linear_ticket_activity', '1_10', { count: 5, authors: { 'Alice' => 5 } }.to_json]
      csv << [today, 'linear_ticket_activity', '2_14', '3'] # Legacy format test
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

    it 'sets empty teams when none provided' do
      expect(generator.selected_teams).to eq([])
    end

    it 'uses custom teams when provided' do
      gen = described_class.new(csv_path, days: 90, teams: %w[ATS Platform])
      expect(gen.selected_teams).to eq(%w[ATS Platform])
    end

    it 'discovers all teams when :all is passed' do
      gen = described_class.new(csv_path, days: 90, teams: :all)
      # Team discovery happens from bugs_by_team metrics
      expect(gen.selected_teams).to be_an(Array)
      expect(gen.selected_teams).to include('ATS')
    end

    it 'sets days_to_show' do
      expect(generator.days_to_show).to eq(90)
    end
  end

  describe '#flow_metrics_presented' do
    it 'returns presented flow metrics' do
      expect(generator.flow_metrics_presented).to be_an(Array)
    end

    it 'wraps metrics in presenters when data exists' do
      # We know we have flow metrics in the CSV
      expect(generator.flow_metrics_presented.first).to be_a(WttjMetrics::Presenters::FlowMetricPresenter)
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
      generator.bugs_by_team.each_key do |team|
        expect(teams).to include(team)
      end
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

  describe '#ticket_activity' do
    it 'returns a 7x24 grid' do
      grid = generator.ticket_activity
      expect(grid.size).to eq(7)
      expect(grid.first.size).to eq(24)
    end

    it 'parses JSON values correctly' do
      grid = generator.ticket_activity
      # wday 1 is Monday. In grid, 0=Mon, 6=Sun. So wday 1 -> index 0.
      # hour 10.
      expect(grid[0][10]).to eq({ 'count' => 5, 'authors' => { 'Alice' => 5 } })
    end

    it 'handles legacy integer values' do
      grid = generator.ticket_activity
      # wday 2 is Tuesday. In grid, 1=Tue.
      # hour 14.
      expect(grid[1][14]).to eq(3)
    end
  end

  describe '#cutoff_date' do
    it 'calculates cutoff date based on days_to_show' do
      cutoff = generator.cutoff_date
      expected = (Date.today - 90).to_s
      expect(cutoff).to eq(expected)
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
    end
  end
end
