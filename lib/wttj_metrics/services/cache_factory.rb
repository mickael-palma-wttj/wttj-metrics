# frozen_string_literal: true

module WttjMetrics
  module Services
    # Factory for creating cache instances
    class CacheFactory
      def self.enabled
        Data::FileCache.new
      end

      def self.disabled
        nil
      end

      def self.default
        enabled
      end
    end
  end
end
