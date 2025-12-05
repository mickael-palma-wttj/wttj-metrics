# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'thor'

module WttjMetrics
  VERSION = '1.0.0'

  # Cache management subcommands
  class CacheCommands < Thor
    desc 'clear', 'Clear the cache'
    def clear
      cache = FileCache.new
      cache.clear!
      puts '✅ Cache cleared'
    end

    desc 'path', 'Show cache directory path'
    def path
      cache = FileCache.new
      puts cache.cache_dir
    end
  end

  # Command Line Interface using Thor
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'collect', 'Collect metrics from Linear API and save to CSV'
    option :output, aliases: '-o', type: :string, default: 'tmp/metrics.csv', desc: 'CSV output file path'
    option :cache, type: :boolean, default: true, desc: 'Use cache for API responses'
    option :clear_cache, type: :boolean, default: false, desc: 'Clear cache before fetching'
    def collect
      Config.validate!

      puts "🚀 Starting Linear Metrics Collection - #{Date.today}"

      cache = options[:cache] ? FileCache.new : nil
      cache&.clear! if options[:clear_cache]

      linear = LinearClient.new(cache: cache)

      puts '📊 Fetching data from Linear...'

      issues = linear.fetch_all_issues
      cycles = linear.fetch_cycles
      team_members = linear.fetch_team_members
      workflow_states = linear.fetch_workflow_states

      puts "   Found #{issues.size} issues"
      puts "   Found #{cycles.size} cycles"

      puts '🔢 Calculating metrics...'
      calculator = MetricsCalculator.new(issues, cycles, team_members, workflow_states)
      rows = calculator.calculate_all

      csv_path = options[:output]
      puts "📝 Writing #{rows.size} metrics to CSV: #{csv_path}"
      csv_writer = CsvWriter.new(csv_path)
      csv_writer.write_rows(rows)

      puts '✅ Metrics collected and saved successfully!'

      puts "\nMetrics Summary:"
      summary = rows.select { |r| %w[flow cycle_metrics team issues].include?(r[1]) }.first(6)
      summary.each { |row| puts "  - #{row[2]}: #{row[3]}" }
    end

    desc 'report CSV_FILE', 'Generate HTML report from CSV metrics'
    option :output, aliases: '-o', type: :string, default: 'report/report.html', desc: 'HTML output file path'
    option :days, aliases: '-d', type: :numeric, default: 90, desc: 'Number of days to show in charts'
    option :teams, aliases: '-t', type: :array,
                   desc: 'Teams to include (default: ATS, Marketplace, Platform, ROI, Sourcing)'
    option :all_teams, type: :boolean, default: false, desc: 'Include all teams (no filter)'
    option :excel, aliases: '-x', type: :boolean, default: false, desc: 'Also generate Excel spreadsheet'
    option :excel_path, type: :string, default: 'report/report.xlsx', desc: 'Excel output file path'
    def report(csv_file)
      raise Error, "CSV file not found: #{csv_file}" unless File.exist?(csv_file)

      # Ensure output directory exists
      output_dir = File.dirname(options[:output])
      FileUtils.mkdir_p(output_dir) unless output_dir == '.'

      # Determine teams: --all-teams means nil (no filter), otherwise use --teams or default
      teams = options[:all_teams] ? :all : options[:teams]

      generator = ReportGenerator.new(csv_file, days: options[:days], teams: teams)
      generator.generate_html(options[:output])

      return unless options[:excel]

      excel_dir = File.dirname(options[:excel_path])
      FileUtils.mkdir_p(excel_dir) unless excel_dir == '.'
      generator.generate_excel(options[:excel_path])
    end

    desc 'version', 'Show version'
    def version
      puts "wttj-metrics v#{WttjMetrics::VERSION}"
    end

    desc 'cache SUBCOMMAND', 'Manage cache'
    subcommand 'cache', CacheCommands
  end
end
