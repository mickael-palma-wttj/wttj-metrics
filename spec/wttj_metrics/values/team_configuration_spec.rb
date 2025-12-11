# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe WttjMetrics::Values::TeamConfiguration do
  subject(:config) { described_class.new(config_path) }

  let(:config_file) { Tempfile.new(['teams', '.yml']) }
  let(:config_path) { config_file.path }
  let(:yaml_content) do
    {
      'teams' => {
        'Team A' => {
          'linear' => ['Linear Team A'],
          'github' => ['github-team-a']
        },
        'Team B' => {
          'linear' => ['Linear Team B']
        }
      }
    }
  end

  before do
    File.write(config_path, yaml_content.to_yaml)
  end

  after do
    config_file.close
    config_file.unlink
  end

  describe '#defined_teams' do
    it 'returns list of defined teams' do
      expect(config.defined_teams).to contain_exactly('Team A', 'Team B')
    end
  end

  describe '#patterns_for' do
    it 'returns patterns for given source' do
      expect(config.patterns_for('Team A', :linear)).to eq(['Linear Team A'])
      expect(config.patterns_for('Team A', 'github')).to eq(['github-team-a'])
    end

    it 'returns empty array if source not defined' do
      expect(config.patterns_for('Team B', :github)).to be_empty
    end

    it 'returns empty array if team not found' do
      expect(config.patterns_for('Unknown', :linear)).to be_empty
    end
  end

  context 'when config file does not exist' do
    let(:config_path) { 'non_existent.yml' }

    before do
      allow(File).to receive(:exist?).with('non_existent.yml').and_return(false)
    end

    it 'returns empty defined teams' do
      expect(config.defined_teams).to be_empty
    end

    it 'returns empty patterns' do
      expect(config.patterns_for('Team A', :linear)).to be_empty
    end
  end

  context 'when config file is empty or invalid structure' do
    let(:yaml_content) { {} }

    it 'returns empty defined teams' do
      expect(config.defined_teams).to be_empty
    end
  end
end
