# frozen_string_literal: true

module WttjMetrics
  module Values
    # Value object for collect command options
    class CollectOptions
      attr_reader :output, :cache_enabled, :clear_cache

      def initialize(options_hash)
        @output = options_hash[:output]
        @cache_enabled = options_hash[:cache]
        @clear_cache = options_hash[:clear_cache]
      end
    end
  end
end
