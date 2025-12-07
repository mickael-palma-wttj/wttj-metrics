# frozen_string_literal: true

require 'tempfile'

RSpec.describe WttjMetrics::Data::CsvWriter do
  subject(:writer) { described_class.new(temp_file.path) }

  let(:temp_file) { Tempfile.new(['test', '.csv']) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '.headers' do
    it 'returns the CSV headers' do
      expect(described_class.headers).to eq(%w[date category metric value])
    end
  end

  describe '#write_rows' do
    let(:rows) do
      [
        %w[2024-12-01 flow throughput 10],
        %w[2024-12-02 flow throughput 15],
        %w[2024-12-01 bugs open_bugs 5]
      ]
    end

    it 'writes rows to CSV file' do
      writer.write_rows(rows)

      csv_data = CSV.read(temp_file.path)
      expect(csv_data.size).to eq(4) # Header + 3 rows
      expect(csv_data.first).to eq(%w[date category metric value])
      expect(csv_data[1]).to eq(%w[2024-12-01 flow throughput 10])
    end

    it 'overwrites existing file' do
      writer.write_rows([%w[2024-12-01 flow test 1]])
      writer.write_rows([%w[2024-12-02 bugs test 2]])

      csv_data = CSV.read(temp_file.path)
      expect(csv_data.size).to eq(2) # Header + 1 row (previous data overwritten)
    end
  end

  describe '#append_rows' do
    let(:initial_rows) do
      [
        %w[2024-12-01 flow throughput 10]
      ]
    end

    let(:additional_rows) do
      [
        %w[2024-12-02 flow throughput 15]
      ]
    end

    it 'appends rows to existing file' do
      writer.write_rows(initial_rows)
      writer.append_rows(additional_rows)

      csv_data = CSV.read(temp_file.path)
      expect(csv_data.size).to eq(3) # Header + 2 rows
      expect(csv_data[1]).to eq(%w[2024-12-01 flow throughput 10])
      expect(csv_data[2]).to eq(%w[2024-12-02 flow throughput 15])
    end

    it 'adds headers if file does not exist' do
      new_temp_path = File.join(Dir.tmpdir, 'new_test_metrics.csv')
      File.delete(new_temp_path) if File.exist?(new_temp_path)

      new_writer = described_class.new(new_temp_path)
      new_writer.append_rows(initial_rows)

      csv_data = CSV.read(new_temp_path)
      expect(csv_data.size).to eq(2) # Header + 1 data row
      expect(csv_data.first).to eq(%w[date category metric value])
      expect(csv_data.last).to eq(initial_rows.first)

      File.delete(new_temp_path) if File.exist?(new_temp_path)
    end

    it 'does not duplicate headers when appending' do
      writer.write_rows(initial_rows)
      writer.append_rows(additional_rows)

      csv_data = CSV.read(temp_file.path)
      headers = csv_data.select { |row| row == %w[date category metric value] }
      expect(headers.size).to eq(1)
    end
  end
end
