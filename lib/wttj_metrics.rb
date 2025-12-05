# frozen_string_literal: true

require 'pathname'
require 'zeitwerk'
require 'dotenv'

# Load environment variables
Dotenv.load(File.join(__dir__, '..', '.env'))

# WTTJ Metrics - A tool to collect and report Linear metrics
module WttjMetrics
  APP_ROOT = Pathname.new(File.expand_path('..', __dir__)).freeze

  class Error < StandardError; end

  class << self
    def root
      APP_ROOT
    end

    def loader
      @loader ||= begin
        loader = Zeitwerk::Loader.for_gem
        loader.inflector.inflect('csv_writer' => 'CsvWriter')
        loader.inflector.inflect('cli' => 'CLI')
        loader
      end
    end

    def setup!
      loader.setup
    end

    def eager_load!
      loader.eager_load
    end
  end

  # Configuration
  module Config
    class << self
      def linear_api_url
        'https://api.linear.app/graphql'
      end

      def linear_api_key
        ENV.fetch('LINEAR_API_KEY', nil)
      end

      def csv_output_path
        ENV['CSV_OUTPUT_PATH'] || 'tmp/metrics.csv'
      end

      def validate!
        errors = []
        errors << 'LINEAR_API_KEY is not set' unless linear_api_key

        return if errors.empty?

        raise Error, "Configuration errors:\n#{errors.map { |e| "  - #{e}" }.join("\n")}"
      end
    end
  end
end

WttjMetrics.setup!
