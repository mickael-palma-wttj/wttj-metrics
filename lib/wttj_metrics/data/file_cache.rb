# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'logger'

module WttjMetrics
  module Data
    # File-based cache for API responses
    class FileCache
      DEFAULT_MAX_AGE_HOURS = 24

      def initialize(cache_dir = nil)
        @cache_dir = cache_dir || File.join(WttjMetrics.root, 'tmp', 'cache')
        FileUtils.mkdir_p(@cache_dir)
        @logger = Logger.new($stdout)
        @logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
      end

      def fetch(key, max_age_hours: DEFAULT_MAX_AGE_HOURS)
        data = read(key, max_age_hours: max_age_hours)
        return data if data

        data = yield
        write(key, data)
        data
      end

      def read(key, max_age_hours: DEFAULT_MAX_AGE_HOURS)
        cache_file = File.join(@cache_dir, "#{key}.json")

        if File.exist?(cache_file)
          age_hours = (Time.now - File.mtime(cache_file)) / 3600.0
          if age_hours < max_age_hours
            @logger.info "   📦 Using cached #{key} (#{age_hours.round(1)}h old)"
            return JSON.parse(File.read(cache_file))
          end
        end
        nil
      end

      def write(key, data)
        cache_file = File.join(@cache_dir, "#{key}.json")
        File.write(cache_file, JSON.pretty_generate(data))
      end

      def clear!
        FileUtils.rm_rf(@cache_dir)
        FileUtils.mkdir_p(@cache_dir)
        @logger.info '   🗑️  Cache cleared'
      end

      attr_reader :cache_dir
    end
  end
end
