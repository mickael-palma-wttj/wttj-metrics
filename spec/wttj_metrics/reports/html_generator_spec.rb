# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::HtmlGenerator do
  subject(:generator) { described_class.new(report_generator) }

  let(:report_generator) { instance_double(WttjMetrics::Reports::ReportGenerator, today: '2024-01-15') }
  let(:output_path) { 'tmp/test_report.html' }

  after { FileUtils.rm_f(output_path) }

  describe '#initialize' do
    it 'accepts a report generator instance' do
      expect { generator }.not_to raise_error
    end
  end

  describe '#generate' do
    before do
      allow(generator).to receive(:build_html).and_return('<html>Test</html>')
    end

    it 'writes HTML to file' do
      generator.generate(output_path)
      expect(File.exist?(output_path)).to be true
    end

    it 'writes the correct content' do
      generator.generate(output_path)
      expect(File.read(output_path)).to eq('<html>Test</html>')
    end
  end

  describe '#build_html' do
    context 'when template is missing' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns fallback HTML' do
        html = generator.build_html
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('Linear Metrics Dashboard')
        expect(html).to include('2024-01-15')
      end
    end
  end
end
