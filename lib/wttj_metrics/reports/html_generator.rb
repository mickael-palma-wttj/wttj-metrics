# frozen_string_literal: true

require 'erb'

module WttjMetrics
  module Reports
    # Generates HTML reports using ERB templates
    # Single Responsibility: HTML rendering
    class HtmlGenerator
      def initialize(report_generator)
        @report = report_generator
        @today = report_generator.today
      end

      def generate(output_path)
        html = build_html
        File.write(output_path, html)
      end

      def build_html
        template_path = template_file_path
        File.exist?(template_path) ? render_template(template_path) : build_html_fallback
      end

      private

      def template_file_path
        File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'report.html.erb')
      end

      def render_template(path)
        ERB.new(File.read(path)).result(@report.instance_eval { binding })
      end

      def build_html_fallback
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head><title>Linear Metrics - #{@today}</title></head>
          <body>
            <h1>Linear Metrics Dashboard</h1>
            <p>Generated: #{@today}</p>
            <p>Please run with the proper template file.</p>
          </body>
          </html>
        HTML
      end
    end
  end
end
