# frozen_string_literal: true

require 'erb'

module WttjMetrics
  module Reports
    module Github
      # Handles HTML report generation
      class HtmlReportBuilder
        def initialize(context)
          @context = context
        end

        def build(output_path)
          html = render
          File.write(output_path, html)
          puts "✅ HTML report generated: #{output_path}"
        end

        private

        def render
          template_path = File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'github_report.html.erb')

          if File.exist?(template_path)
            template = ERB.new(File.read(template_path))
            template.result(@context.template_binding)
          else
            build_html_fallback
          end
        end

        def build_html_fallback
          <<~HTML
            <!DOCTYPE html>
            <html>
            <head><title>GitHub Metrics - #{@context.today}</title></head>
            <body>
              <h1>GitHub Metrics Dashboard</h1>
              <p>Generated: #{@context.today}</p>
              <p>Please run with the proper template file.</p>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
