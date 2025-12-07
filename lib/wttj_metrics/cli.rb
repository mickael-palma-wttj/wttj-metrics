# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'thor'
require 'logger'

module WttjMetrics
  VERSION = '1.0.0'

  # Cache management subcommands
  class CacheCommands < Thor
    def initialize(*args)
      super
      @logger = Logger.new($stdout)
      @logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
    end

    desc 'clear', 'Clear the cache'
    def clear
      cache = Data::FileCache.new
      cache.clear!
      @logger.info '✅ Cache cleared'
    end

    desc 'path', 'Show cache directory path'
    def path
      cache = Data::FileCache.new
      @logger.info cache.cache_dir
    end
  end

  # Command Line Interface using Thor
  class CLI < Thor
    def initialize(*args)
      super
      @logger = Logger.new($stdout)
      @logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
    end

    def self.exit_on_failure?
      true
    end

    desc 'collect', 'Collect metrics from Linear API and save to CSV'
    option :output, aliases: '-o', type: :string, default: 'tmp/metrics.csv', desc: 'CSV output file path'
    option :cache, type: :boolean, default: true, desc: 'Use cache for API responses'
    option :clear_cache, type: :boolean, default: false, desc: 'Clear cache before fetching'
    def collect
      Config.validate!

      @logger.info "🚀 Starting Linear Metrics Collection - #{Date.today}"

      cache = options[:cache] ? Data::FileCache.new : nil
      cache&.clear! if options[:clear_cache]

      linear = Sources::Linear::Client.new(cache: cache)

      @logger.info '📊 Fetching data from Linear...'

      issues = linear.fetch_all_issues
      cycles = linear.fetch_cycles
      team_members = linear.fetch_team_members
      workflow_states = linear.fetch_workflow_states

      @logger.info "   Found #{issues.size} issues"
      @logger.info "   Found #{cycles.size} cycles"

      @logger.info '🔢 Calculating metrics...'
      calculator = Metrics::Calculator.new(issues, cycles, team_members, workflow_states)
      rows = calculator.calculate_all

      csv_path = options[:output]
      @logger.info "📝 Writing #{rows.size} metrics to CSV: #{csv_path}"
      csv_writer = Data::CsvWriter.new(csv_path)
      csv_writer.write_rows(rows)

      @logger.info '✅ Metrics collected and saved successfully!'

      @logger.info "\nMetrics Summary:"
      summary_categories = %w[flow cycle_metrics team issues]
      summary = rows.select { |r| summary_categories.include?(r[1]) }.first(6)
      summary.each { |row| @logger.info "  - #{row[2]}: #{row[3]}" }
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

      generator = Reports::ReportGenerator.new(csv_file, days: options[:days], teams: teams)
      generator.generate_html(options[:output])

      return unless options[:excel]

      excel_dir = File.dirname(options[:excel_path])
      FileUtils.mkdir_p(excel_dir) unless excel_dir == '.'
      generator.generate_excel(options[:excel_path])
    end

    desc 'version', 'Show version'
    def version
      @logger.info "wttj-metrics v#{WttjMetrics::VERSION}"
    end

    desc 'cache SUBCOMMAND', 'Manage cache'
    subcommand 'cache', CacheCommands
  end
end
