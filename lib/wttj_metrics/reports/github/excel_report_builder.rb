# frozen_string_literal: true

require 'axlsx'

module WttjMetrics
  module Reports
    module Github
      # Builds Excel reports from GitHub metrics data
      class ExcelReportBuilder
        def initialize(data)
          @data = data
          @package = Axlsx::Package.new
          @workbook = @package.workbook
          @header_style = create_header_style
        end

        def build(output_path)
          add_key_metrics_sheet
          add_daily_breakdown_sheet
          add_raw_data_sheet

          @package.serialize(output_path)
        end

        private

        def create_header_style
          @workbook.styles.add_style(
            bg_color: '2D3748',
            fg_color: 'FFFFFF',
            b: true,
            alignment: { horizontal: :center },
            border: { style: :thin, color: '4A5568' }
          )
        end

        def add_key_metrics_sheet
          @workbook.add_worksheet(name: 'Key Metrics') do |sheet|
            sheet.add_row ["GitHub Metrics Report - #{@data[:today]}"], style: @header_style
            sheet.merge_cells('A1:B1')
            sheet.add_row []

            sheet.add_row %w[Metric Value], style: @header_style

            metrics = @data[:metrics]
            add_metric_row(sheet, 'Avg Time to Merge', metrics[:avg_time_to_merge], 'days')
            add_metric_row(sheet, 'Total Merged PRs', metrics[:total_merged], '')
            add_metric_row(sheet, 'Avg Reviews/PR', metrics[:avg_reviews], '')
            add_metric_row(sheet, 'Avg Comments/PR', metrics[:avg_comments], '')
            add_metric_row(sheet, 'Avg Time to First Review', metrics[:avg_time_to_first_review], 'days')
            add_metric_row(sheet, 'Avg Additions/PR', metrics[:avg_additions], '')
            add_metric_row(sheet, 'Avg Deletions/PR', metrics[:avg_deletions], '')
            add_metric_row(sheet, 'Avg Changed Files/PR', metrics[:avg_changed_files], '')
            add_metric_row(sheet, 'Avg Commits/PR', metrics[:avg_commits], '')

            sheet.column_widths 30, 20
          end
        end

        def add_metric_row(sheet, label, value, unit)
          formatted_value = value.is_a?(Float) ? value.round(1) : value.to_i
          unit_suffix = unit.empty? ? '' : " #{unit}"
          sheet.add_row [label, "#{formatted_value}#{unit_suffix}"]
        end

        def add_daily_breakdown_sheet
          @workbook.add_worksheet(name: 'Daily Breakdown') do |sheet|
            headers = %w[Date Merged Closed Open Avg_Merge_Time(h) Avg_Reviews Avg_Comments Avg_Additions
                         Avg_Deletions Avg_Time_To_First_Review(h)]
            sheet.add_row headers, style: @header_style

            daily = @data[:daily_breakdown]
            datasets = daily[:datasets]
            daily[:labels].each_with_index do |date, index|
              sheet.add_row [
                date,
                datasets[:merged][index],
                datasets[:closed][index],
                datasets[:open][index],
                datasets[:avg_time_to_merge][index],
                datasets[:avg_reviews][index],
                datasets[:avg_comments][index],
                datasets[:avg_additions][index],
                datasets[:avg_deletions][index],
                datasets[:avg_time_to_first_review][index]
              ]
            end
          end
        end

        def add_raw_data_sheet
          @workbook.add_worksheet(name: 'Raw Data') do |sheet|
            sheet.add_row %w[Date Category Metric Value], style: @header_style
            @data[:raw_data].each do |row|
              sheet.add_row [row['date'], row['category'], row['metric'], row['value']]
            end
          end
        end
      end
    end
  end
end
