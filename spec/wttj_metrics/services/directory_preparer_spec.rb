# frozen_string_literal: true

require 'tmpdir'

RSpec.describe WttjMetrics::Services::DirectoryPreparer do
  describe '.ensure_exists' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:nested_path) { File.join(temp_dir, 'reports', 'output', 'file.html') }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'creates nested directories when they do not exist' do
      described_class.ensure_exists(nested_path)

      expect(File.directory?(File.dirname(nested_path))).to be true
    end

    it 'does not raise error when directory already exists' do
      FileUtils.mkdir_p(File.dirname(nested_path))

      expect do
        described_class.ensure_exists(nested_path)
      end.not_to raise_error
    end

    context 'when path is in current directory' do
      it 'does not try to create directory for current dir' do
        allow(FileUtils).to receive(:mkdir_p)

        described_class.ensure_exists('file.html')

        expect(FileUtils).not_to have_received(:mkdir_p)
      end

      it 'does not try to create directory for explicit current dir' do
        allow(FileUtils).to receive(:mkdir_p)

        described_class.ensure_exists('./file.html')

        expect(FileUtils).not_to have_received(:mkdir_p)
      end
    end

    context 'with absolute paths' do
      it 'creates the full directory structure' do
        absolute_path = File.join(temp_dir, 'deep', 'nested', 'structure', 'file.csv')

        described_class.ensure_exists(absolute_path)

        expect(File.directory?(File.dirname(absolute_path))).to be true
      end
    end

    context 'with existing parent directories' do
      it 'only creates missing directories' do
        partial_dir = File.join(temp_dir, 'existing')
        FileUtils.mkdir_p(partial_dir)

        full_path = File.join(partial_dir, 'new', 'file.txt')
        described_class.ensure_exists(full_path)

        expect(File.directory?(File.dirname(full_path))).to be true
      end
    end
  end

  describe '.current_directory?' do
    it 'is a private method' do
      expect(described_class.private_methods).to include(:current_directory?)
    end
  end
end
