# frozen_string_literal: true

require 'tempfile'

RSpec.describe WttjMetrics::Reports::Github::ExcelReportBuilder do
  subject(:builder) { described_class.new(report_data) }

  let(:temp_file) { Tempfile.new(['github_report', '.xlsx']) }
  let(:report_data) do
    {
      today: '2024-12-09',
      metrics: {
        avg_time_to_merge: 2.5,
        total_merged: 100,
        avg_reviews: 3.2,
        avg_comments: 5.1,
        avg_time_to_first_review: 1.1,
        avg_additions: 150,
        avg_deletions: 50,
        avg_changed_files: 4.5,
        avg_commits: 2.1
      },
      daily_breakdown: {
        labels: %w[2024-12-01 2024-12-02],
        datasets: {
          merged: [5, 8],
          closed: [1, 0],
          open: [10, 12],
          avg_time_to_merge: [24.0, 12.0],
          avg_reviews: [3.0, 4.0],
          avg_comments: [5.0, 6.0],
          avg_additions: [100, 200],
          avg_deletions: [20, 30],
          avg_time_to_first_review: [10.0, 5.0]
        }
      },
      raw_data: [
        { 'date' => '2024-12-01', 'category' => 'github', 'metric' => 'merged', 'value' => 5 }
      ]
    }
  end

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#build' do
    it 'creates an Excel file' do
      builder.build(temp_file.path)
      expect(File.exist?(temp_file.path)).to be true
      expect(File.size(temp_file.path)).to be > 0
    end
  end
end
