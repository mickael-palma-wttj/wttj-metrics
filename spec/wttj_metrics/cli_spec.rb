# frozen_string_literal: true

require 'tempfile'

RSpec.describe WttjMetrics::CLI do
  let(:cli) { described_class.new }

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe '#version' do
    it 'prints version information' do
      expect { cli.version }.to output(/wttj-metrics v#{WttjMetrics::VERSION}/o).to_stdout
    end
  end

  describe '#collect' do
    let(:linear_client) { instance_double(WttjMetrics::Sources::Linear::Client) }
    let(:calculator) { instance_double(WttjMetrics::Metrics::Linear::Calculator) }
    let(:csv_writer) { instance_double(WttjMetrics::Data::CsvWriter) }
    let(:cache) { instance_double(WttjMetrics::Data::FileCache) }

    let(:issues) { [{ 'id' => '1' }, { 'id' => '2' }] }
    let(:cycles) { [{ 'id' => 'c1' }] }
    let(:team_members) { [{ 'name' => 'Alice' }] }
    let(:workflow_states) { [{ 'name' => 'Backlog' }] }
    let(:rows) do
      [
        ['2024-12-05', 'flow', 'throughput', 10],
        ['2024-12-05', 'flow', 'wip', 5],
        ['2024-12-05', 'cycle_metrics', 'velocity', 42],
        ['2024-12-05', 'team', 'Team A', 100],
        ['2024-12-05', 'issues', 'total', 50],
        ['2024-12-05', 'bugs', 'open_bugs', 3]
      ]
    end

    before do
      allow(WttjMetrics::Config).to receive(:validate!)
      allow(WttjMetrics::Sources::Linear::Client).to receive(:new).and_return(linear_client)
      allow(WttjMetrics::Metrics::Linear::Calculator).to receive(:new).and_return(calculator)
      allow(WttjMetrics::Data::CsvWriter).to receive(:new).and_return(csv_writer)
      allow(WttjMetrics::Data::FileCache).to receive(:new).and_return(cache)

      allow(linear_client).to receive_messages(fetch_all_issues: issues, fetch_cycles: cycles,
                                               fetch_team_members: team_members, fetch_workflow_states: workflow_states)
      allow(calculator).to receive(:calculate_all).and_return(rows)
      allow(csv_writer).to receive(:write_rows)
      allow(cache).to receive(:clear!)
    end

    context 'with default options' do
      before do
        allow(cli).to receive(:options).and_return({ cache: true, clear_cache: false, output: 'tmp/metrics.csv' })
      end

      it 'validates configuration' do
        expect(WttjMetrics::Config).to receive(:validate!)
        cli.collect
      end

      it 'creates Linear client with cache' do
        expect(WttjMetrics::Sources::Linear::Client).to receive(:new).with(cache: cache)
        cli.collect
      end

      it 'fetches all data from Linear' do
        expect(linear_client).to receive(:fetch_all_issues)
        expect(linear_client).to receive(:fetch_cycles)
        expect(linear_client).to receive(:fetch_team_members)
        expect(linear_client).to receive(:fetch_workflow_states)
        cli.collect
      end

      it 'calculates metrics' do
        expect(calculator).to receive(:calculate_all)
        cli.collect
      end

      it 'writes rows to CSV' do
        expect(csv_writer).to receive(:write_rows).with(rows)
        cli.collect
      end

      it 'outputs success messages' do
        output = StringIO.new
        logger = Logger.new(output)
        allow(Logger).to receive(:new).and_return(logger)

        cli = described_class.new
        allow(cli).to receive(:options).and_return({ cache: true, clear_cache: false, output: 'tmp/metrics.csv' })

        cli.collect

        logged_output = output.string
        expect(logged_output).to match(/Starting Linear Metrics Collection/)
        expect(logged_output).to match(/Fetching data from Linear/)
        expect(logged_output).to match(/Found 2 issues/)
        expect(logged_output).to match(/Found 1 cycles/)
        expect(logged_output).to match(/Calculating metrics/)
        expect(logged_output).to match(/Metrics collected and saved successfully/)
      end

      it 'outputs metrics summary' do
        output = StringIO.new
        logger = Logger.new(output)
        allow(Logger).to receive(:new).and_return(logger)

        cli = described_class.new
        allow(cli).to receive(:options).and_return({ cache: true, clear_cache: false, output: 'tmp/metrics.csv' })

        cli.collect

        logged_output = output.string
        expect(logged_output).to match(/Metrics Summary:/)
        expect(logged_output).to match(/throughput: 10/)
      end
    end

    context 'with cache disabled' do
      before do
        allow(cli).to receive(:options).and_return({ cache: false, clear_cache: false, output: 'tmp/metrics.csv' })
      end

      it 'creates Linear client without cache' do
        expect(WttjMetrics::Sources::Linear::Client).to receive(:new).with(cache: nil)
        cli.collect
      end
    end

    context 'with clear_cache option' do
      before do
        allow(cli).to receive(:options).and_return({ cache: true, clear_cache: true, output: 'tmp/metrics.csv' })
      end

      it 'clears cache before fetching' do
        expect(cache).to receive(:clear!)
        cli.collect
      end
    end

    context 'with custom output path' do
      before do
        allow(cli).to receive(:options).and_return({ cache: true, clear_cache: false, output: 'custom/path.csv' })
      end

      it 'creates CSV writer with custom path' do
        expect(WttjMetrics::Data::CsvWriter).to receive(:new).with('custom/path.csv')
        cli.collect
      end
    end
  end

  describe '#report' do
    let(:csv_file) { Tempfile.new(['metrics', '.csv']).path }
    let(:generator) { instance_double(WttjMetrics::Reports::ReportGenerator) }

    before do
      allow(WttjMetrics::Reports::ReportGenerator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate_html)
      allow(generator).to receive(:generate_excel)
      allow(FileUtils).to receive(:mkdir_p)
    end

    after do
      FileUtils.rm_f(csv_file)
    end

    context 'with valid CSV file' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report/report.html',
                                                     days: 90,
                                                     teams: nil,
                                                     all_teams: false,
                                                     excel: false,
                                                     excel_path: 'report/report.xlsx'
                                                   })
      end

      it 'creates report generator with CSV file' do
        expect(WttjMetrics::Reports::ReportGenerator).to receive(:new).with(csv_file, days: 90, teams: nil)
        cli.report(csv_file)
      end

      it 'generates HTML report' do
        expect(generator).to receive(:generate_html).with('report/report.html')
        cli.report(csv_file)
      end

      it 'creates output directory if needed' do
        expect(FileUtils).to receive(:mkdir_p).with('report')
        cli.report(csv_file)
      end
    end

    context 'with all_teams option' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report.html',
                                                     days: 90,
                                                     teams: nil,
                                                     all_teams: true,
                                                     excel: false,
                                                     excel_path: 'report.xlsx'
                                                   })
      end

      it 'passes :all as teams parameter' do
        expect(WttjMetrics::Reports::ReportGenerator).to receive(:new).with(csv_file, days: 90, teams: :all)
        cli.report(csv_file)
      end
    end

    context 'with custom teams' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report.html',
                                                     days: 90,
                                                     teams: %w[Platform ATS],
                                                     all_teams: false,
                                                     excel: false,
                                                     excel_path: 'report.xlsx'
                                                   })
      end

      it 'passes specified teams' do
        expect(WttjMetrics::Reports::ReportGenerator).to receive(:new).with(csv_file, days: 90,
                                                                                      teams: %w[Platform ATS])
        cli.report(csv_file)
      end
    end

    context 'with custom days' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report.html',
                                                     days: 30,
                                                     teams: nil,
                                                     all_teams: false,
                                                     excel: false,
                                                     excel_path: 'report.xlsx'
                                                   })
      end

      it 'passes custom days to generator' do
        expect(WttjMetrics::Reports::ReportGenerator).to receive(:new).with(csv_file, days: 30, teams: nil)
        cli.report(csv_file)
      end
    end

    context 'with excel option enabled' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report.html',
                                                     days: 90,
                                                     teams: nil,
                                                     all_teams: false,
                                                     excel: true,
                                                     excel_path: 'report/report.xlsx'
                                                   })
      end

      it 'generates Excel report' do
        expect(generator).to receive(:generate_excel).with('report/report.xlsx')
        cli.report(csv_file)
      end

      it 'creates Excel output directory if needed' do
        expect(FileUtils).to receive(:mkdir_p).with('report')
        cli.report(csv_file)
      end
    end

    context 'with non-existent CSV file' do
      it 'raises an error' do
        expect { cli.report('nonexistent.csv') }.to raise_error(WttjMetrics::Error, /CSV file not found/)
      end
    end

    context 'with output in current directory' do
      before do
        allow(cli).to receive(:options).and_return({
                                                     output: 'report.html',
                                                     days: 90,
                                                     teams: nil,
                                                     all_teams: false,
                                                     excel: false,
                                                     excel_path: 'report.xlsx'
                                                   })
      end

      it 'does not try to create directory for current dir' do
        expect(FileUtils).not_to receive(:mkdir_p).with('.')
        cli.report(csv_file)
      end
    end
  end
end

RSpec.describe WttjMetrics::CacheCommands do
  let(:cache_commands) { described_class.new }
  let(:cache) { instance_double(WttjMetrics::Data::FileCache) }

  before do
    allow(WttjMetrics::Data::FileCache).to receive(:new).and_return(cache)
  end

  describe '#clear' do
    before do
      allow(cache).to receive(:clear!)
    end

    it 'clears the cache' do
      expect(cache).to receive(:clear!)
      cache_commands.clear
    end

    it 'outputs success message' do
      expect { cache_commands.clear }.to output(/Cache cleared/).to_stdout
    end
  end

  describe '#path' do
    before do
      allow(cache).to receive(:cache_dir).and_return('/tmp/cache')
    end

    it 'outputs cache directory path' do
      expect { cache_commands.path }.to output("/tmp/cache\n").to_stdout
    end
  end
end
