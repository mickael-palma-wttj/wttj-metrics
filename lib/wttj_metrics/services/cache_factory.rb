# frozen_string_literal: true

module WttjMetrics
  module Services
    # Factory for creating cache instances
    class CacheFactory
      def self.build(enabled: true)
        return nil unless enabled

        Data::FileCache.new
      end

      def self.default
        build(enabled: true)
      end
    end
  end
end
