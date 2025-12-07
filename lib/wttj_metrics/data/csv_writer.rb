# frozen_string_literal: true

require 'csv'

module WttjMetrics
  module Data
    # Writes metrics to CSV files
    class CsvWriter
      HEADERS = %w[date category metric value].freeze

      def initialize(file_path)
        @file_path = file_path
      end

      def write_rows(rows)
        CSV.open(@file_path, 'w') do |csv|
          csv << HEADERS
          rows.each { |row| csv << row }
        end
      end

      def append_rows(rows)
        file_exists = File.exist?(@file_path)

        CSV.open(@file_path, 'a') do |csv|
          csv << HEADERS unless file_exists
          rows.each { |row| csv << row }
        end
      end

      def self.headers
        HEADERS
      end
    end
  end
end
