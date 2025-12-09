# frozen_string_literal: true

RSpec.describe WttjMetrics::Helpers::Linear::IssueHelper do
  subject(:helper) { test_class.new }

  let(:test_class) do
    Class.new do
      include WttjMetrics::Helpers::Linear::IssueHelper
    end
  end
  let(:bug_issue) do
    {
      'labels' => { 'nodes' => [{ 'name' => 'Bug' }] },
      'team' => { 'name' => 'Platform' },
      'assignee' => { 'name' => 'John Doe' },
      'priorityLabel' => 'High',
      'completedAt' => '2024-12-05',
      'startedAt' => '2024-12-01'
    }
  end
  let(:feature_issue) do
    {
      'labels' => { 'nodes' => [{ 'name' => 'Feature' }] },
      'team' => { 'name' => 'ATS' },
      'assignee' => nil,
      'priorityLabel' => nil,
      'completedAt' => nil,
      'startedAt' => nil
    }
  end

  describe '#issue_is_bug?' do
    it 'returns true for issues with bug label' do
      expect(helper.issue_is_bug?(bug_issue)).to be true
    end

    it 'returns false for non-bug issues' do
      expect(helper.issue_is_bug?(feature_issue)).to be false
    end

    it 'returns true for issues with fix label' do
      fix_issue = { 'labels' => { 'nodes' => [{ 'name' => 'Hotfix' }] } }
      expect(helper.issue_is_bug?(fix_issue)).to be true
    end
  end

  describe '#extract_labels' do
    it 'returns lowercase label names' do
      expect(helper.extract_labels(bug_issue)).to eq(['bug'])
    end

    it 'returns empty array when no labels' do
      issue = { 'labels' => nil }
      expect(helper.extract_labels(issue)).to eq([])
    end
  end

  describe '#extract_team_name' do
    it 'returns team name' do
      expect(helper.extract_team_name(bug_issue)).to eq('Platform')
    end

    it 'returns Unknown when no team' do
      issue = { 'team' => nil }
      expect(helper.extract_team_name(issue)).to eq('Unknown')
    end
  end

  describe '#extract_assignee_name' do
    it 'returns assignee name' do
      expect(helper.extract_assignee_name(bug_issue)).to eq('John Doe')
    end

    it 'returns Unassigned when no assignee' do
      expect(helper.extract_assignee_name(feature_issue)).to eq('Unassigned')
    end
  end

  describe '#extract_priority_label' do
    it 'returns priority label' do
      expect(helper.extract_priority_label(bug_issue)).to eq('High')
    end

    it 'returns No priority when no priority set' do
      expect(helper.extract_priority_label(feature_issue)).to eq('No priority')
    end
  end

  describe '#issue_completed?' do
    it 'returns true when completedAt is set' do
      expect(helper.issue_completed?(bug_issue)).to be true
    end

    it 'returns false when completedAt is nil' do
      expect(helper.issue_completed?(feature_issue)).to be false
    end
  end

  describe '#issue_started?' do
    it 'returns true when startedAt is set' do
      expect(helper.issue_started?(bug_issue)).to be true
    end

    it 'returns false when startedAt is nil' do
      expect(helper.issue_started?(feature_issue)).to be false
    end
  end
end
