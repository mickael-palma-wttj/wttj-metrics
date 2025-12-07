# frozen_string_literal: true

require 'tempfile'

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
      File.delete(output_path) if File.exist?(output_path)
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
      File.delete(output_path) if File.exist?(output_path)
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
end
