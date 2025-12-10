# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Github::ReportGenerator do
  let(:csv_path) { 'spec/fixtures/github_metrics.csv' }
  let(:generator) { described_class.new(csv_path) }
  let(:today) { Date.today.to_s }
  let(:yesterday) { (Date.today - 1).to_s }

  before do
    allow(Date).to receive(:today).and_return(Date.parse('2025-12-09'))

    # Mock CsvParser
    parser = instance_double(WttjMetrics::Data::CsvParser)
    allow(WttjMetrics::Data::CsvParser).to receive(:new).with(csv_path).and_return(parser)

    metrics_data = [
      { date: yesterday, metric: 'avg_time_to_merge_days', value: 2.5 },
      { date: today, metric: 'avg_time_to_merge_days', value: 2.0 },
      { date: yesterday, metric: 'total_merged_prs', value: 10 },
      { date: today, metric: 'total_merged_prs', value: 15 },
      { date: yesterday, metric: 'avg_reviews_per_pr', value: 1.5 },
      { date: today, metric: 'avg_reviews_per_pr', value: 1.8 },
      { date: yesterday, metric: 'avg_comments_per_pr', value: 3.0 },
      { date: today, metric: 'avg_comments_per_pr', value: 3.5 },
      { date: today, metric: 'avg_additions_per_pr', value: 100 },
      { date: today, metric: 'avg_deletions_per_pr', value: 50 },
      { date: today, metric: 'avg_changed_files_per_pr', value: 5 },
      { date: today, metric: 'avg_commits_per_pr', value: 2 },
      { date: today, metric: 'avg_time_to_first_review_days', value: 0.5 }
    ]

    allow(parser).to receive_messages(data: [], metrics_by_category: { 'github' => metrics_data })
  end

  describe '#metrics' do
    it 'returns latest metrics' do
      expect(generator.metrics).to eq({
                                        avg_time_to_merge: 2.0,
                                        total_merged: 15,
                                        avg_reviews: 1.8,
                                        avg_comments: 3.5,
                                        avg_additions: 100,
                                        avg_deletions: 50,
                                        avg_changed_files: 5,
                                        avg_commits: 2,
                                        avg_time_to_first_review: 0.5,
                                        merge_rate: 0,
                                        avg_time_to_approval: 0,
                                        avg_rework_cycles: 0,
                                        unreviewed_pr_rate: 0,
                                        ci_success_rate: 0,
                                        deploy_frequency: 0,
                                        deploy_frequency_daily: 0.0,
                                        hotfix_rate: 0,
                                        time_to_green: 0
                                      })
    end
  end

  describe '#history' do
    it 'returns history for each metric' do
      history = generator.history

      expect(history[:avg_time_to_merge]).to eq([
                                                  { date: yesterday, value: 2.5 },
                                                  { date: today, value: 2.0 }
                                                ])

      expect(history[:total_merged]).to eq([
                                             { date: yesterday, value: 10 },
                                             { date: today, value: 15 }
                                           ])
    end
  end

  describe '#generate_html' do
    let(:output_path) { 'tmp/report.html' }

    before do
      allow(File).to receive(:write)
      allow(File).to receive_messages(read: 'Template content', exist?: true)
    end

    it 'writes HTML report' do
      generator.generate_html(output_path)
      expect(File).to have_received(:write).with(output_path, anything)
    end
  end

  describe '#weekly_breakdown' do
    before do
      daily_data = [
        { date: '2025-12-01', metric: 'merged', value: 5 },
        { date: '2025-12-01', metric: 'closed', value: 2 },
        { date: '2025-12-01', metric: 'open', value: 10 },
        { date: '2025-12-01', metric: 'created', value: 10 },
        { date: '2025-12-01', metric: 'avg_time_to_merge_hours', value: 10.0 },
        { date: '2025-12-02', metric: 'merged', value: 5 },
        { date: '2025-12-02', metric: 'closed', value: 3 },
        { date: '2025-12-02', metric: 'open', value: 12 },
        { date: '2025-12-02', metric: 'created', value: 10 },
        { date: '2025-12-02', metric: 'avg_time_to_merge_hours', value: 20.0 },
        { date: '2025-12-08', metric: 'merged', value: 8 },
        { date: '2025-12-08', metric: 'closed', value: 4 },
        { date: '2025-12-08', metric: 'open', value: 15 },
        { date: '2025-12-08', metric: 'created', value: 20 },
        { date: '2025-12-08', metric: 'avg_time_to_merge_hours', value: 5.0 }
      ]

      parser = instance_double(WttjMetrics::Data::CsvParser)
      allow(WttjMetrics::Data::CsvParser).to receive(:new).with(csv_path).and_return(parser)
      allow(parser).to receive_messages(data: [], metrics_by_category: { 'github' => [], 'github_daily' => daily_data })
    end

    it 'aggregates metrics by week' do
      breakdown = generator.weekly_breakdown

      expect(breakdown[:labels]).to include('2025-12-01', '2025-12-08')
      expect(breakdown[:datasets][:merged]).to eq([10, 8])
      expect(breakdown[:datasets][:open]).to eq([12, 15])
      expect(breakdown[:datasets][:avg_time_to_merge]).to eq([15.0, 5.0])
    end
  end
end
