# frozen_string_literal: true

require 'logger'

module WttjMetrics
  module Helpers
    # Shared logger configuration for CLI classes
    module LoggerMixin
      private

      def logger
        @logger ||= create_logger
      end

      def create_logger
        Logger.new($stdout).tap do |log|
          log.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
        end
      end
    end
  end
end
