# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'thor'

module WttjMetrics
  VERSION = '1.0.0'

  # Cache management subcommands
  class CacheCommands < Thor
    include Helpers::LoggerMixin

    desc 'clear', 'Clear the cache'
    def clear
      cache = Services::CacheFactory.default
      cache.clear!
      logger.info '✅ Cache cleared'
    end

    desc 'path', 'Show cache directory path'
    def path
      cache = Services::CacheFactory.default
      logger.info cache.cache_dir
    end
  end

  # Command Line Interface using Thor
  class CLI < Thor
    include Helpers::LoggerMixin

    DEFAULT_REPORT_DAYS = 90

    def self.exit_on_failure?
      true
    end

    desc 'collect', 'Collect metrics from Linear API and save to CSV'
    option :output, aliases: '-o', type: :string, default: 'tmp/metrics.csv', desc: 'CSV output file path'
    option :cache, type: :boolean, default: true, desc: 'Use cache for API responses'
    option :clear_cache, type: :boolean, default: false, desc: 'Clear cache before fetching'
    option :sources, aliases: '-s', type: :array, default: ['linear'],
                     desc: 'Data sources to collect from (linear, github)'
    option :days, aliases: '-d', type: :numeric, default: DEFAULT_REPORT_DAYS,
                  desc: 'Number of days to collect data for'
    def collect
      collect_options = options.dup

      if collect_options[:output] == 'tmp/metrics.csv'
        collect_options[:sources].each do |source|
          opts = collect_options.dup
          opts[:sources] = [source]
          opts[:output] = "tmp/#{source}_metrics.csv"

          Services::MetricsCollector.new(Values::CollectOptions.new(opts), logger).call
        end
      else
        opts = Values::CollectOptions.new(collect_options)
        Services::MetricsCollector.new(opts, logger).call
      end
    end

    desc 'report [CSV_FILE]', 'Generate HTML report from CSV metrics'
    option :output, aliases: '-o', type: :string, default: 'report/report.html', desc: 'HTML output file path'
    option :days, aliases: '-d', type: :numeric, default: DEFAULT_REPORT_DAYS, desc: 'Number of days to show in charts'
    option :teams, aliases: '-t', type: :array,
                   desc: 'Teams to include (default: ats, marketplace, platform, sourcing)'
    option :teams_config, aliases: '-c', type: :string, default: 'lib/config/teams.yml',
                          desc: 'Path to teams configuration YAML file'
    option :all_teams, type: :boolean, default: false, desc: 'Include all teams (no filter)'
    option :excel, aliases: '-x', type: :boolean, default: false, desc: 'Also generate Excel spreadsheet'
    option :excel_path, type: :string, default: 'report/report.xlsx', desc: 'Excel output file path'
    option :sources, aliases: '-s', type: :array, default: ['linear'],
                     desc: 'Data sources to include in filename resolution (linear, github)'
    def report(csv_file = 'tmp/metrics.csv')
      if csv_file == 'tmp/metrics.csv'
        options[:sources].each do |source|
          opts = options.dup
          input_csv = "tmp/#{source}_metrics.csv"

          opts[:output] = "report/#{source}_report.html" if opts[:output] == 'report/report.html'
          opts[:excel_path] = "report/#{source}_report.xlsx" if opts[:excel_path] == 'report/report.xlsx'

          Services::ReportService.new(input_csv, Values::ReportOptions.new(opts), logger).call
        end
      else
        opts = Values::ReportOptions.new(options)
        Services::ReportService.new(csv_file, opts, logger).call
      end
    end

    desc 'version', 'Show version'
    def version
      logger.info "wttj-metrics v#{WttjMetrics::VERSION}"
    end

    desc 'cache SUBCOMMAND', 'Manage cache'
    subcommand 'cache', CacheCommands
  end
end
