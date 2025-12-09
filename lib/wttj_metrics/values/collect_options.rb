# frozen_string_literal: true

module WttjMetrics
  module Values
    # Value object for collect command options
    class CollectOptions
      attr_reader :output, :cache_enabled, :clear_cache, :sources, :days

      def initialize(options_hash)
        @output = options_hash[:output]
        @cache_enabled = options_hash[:cache]
        @clear_cache = options_hash[:clear_cache]
        @sources = options_hash[:sources] || ['linear']
        @days = options_hash[:days] || 90
      end
    end
  end
end
