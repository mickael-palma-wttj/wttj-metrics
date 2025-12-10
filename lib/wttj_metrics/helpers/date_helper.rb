# frozen_string_literal: true

require 'date'

module WttjMetrics
  module Helpers
    # Common date manipulation helpers
    module DateHelper
      def parse_date(date_string, format: :date)
        return nil unless date_string

        parsed = Date.parse(date_string.to_s)
        format == :string ? parsed.to_s : parsed
      rescue Date::Error
        nil
      end

      def parse_datetime(date_string)
        DateTime.parse(date_string) if date_string
      end

      def monday_of_week(date)
        date = Date.parse(date) if date.is_a?(String)
        date - ((date.wday - 1) % 7)
      end

      def format_week_label(date)
        monday = monday_of_week(date)
        monday.strftime('%b %d')
      end

      def days_ago(days, from: Date.today)
        (from - days).to_s
      end

      def days_between(start_date, end_date)
        return nil unless start_date && end_date

        start_d = start_date.is_a?(Date) ? start_date : Date.parse(start_date)
        end_d = end_date.is_a?(Date) ? end_date : Date.parse(end_date)
        (end_d - start_d).to_i
      end

      def hours_between(start_time, end_time)
        return nil unless start_time && end_time

        start_t = start_time.is_a?(DateTime) ? start_time : DateTime.parse(start_time)
        end_t = end_time.is_a?(DateTime) ? end_time : DateTime.parse(end_time)
        ((end_t - start_t) * 24).to_f
      end
    end
  end
end
