# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WttjMetrics::Reports::Github::HtmlReportBuilder do
  subject(:builder) { described_class.new(context) }

  let(:context_helper) do
    Class.new do
      def today
        Date.today
      end

      def template_binding
        binding
      end
    end.new
  end

  let(:context) { context_helper }
  let(:output_path) { 'tmp/test_report.html' }
  let(:template_path) { File.join(WttjMetrics.root, 'lib', 'wttj_metrics', 'templates', 'github_report.html.erb') }

  before do
    allow(File).to receive(:write)
    allow(File).to receive(:exist?).with(template_path).and_return(true)
    allow(File).to receive(:read).with(template_path).and_return('<html><%= today %></html>')
  end

  describe '#build' do
    it 'renders the template and writes to file' do
      builder.build(output_path)
      expect(File).to have_received(:write).with(output_path, "<html>#{Date.today}</html>")
    end

    context 'when template file does not exist' do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(false)
      end

      it 'renders fallback HTML' do
        builder.build(output_path)
        expect(File).to have_received(:write).with(output_path, include('GitHub Metrics Dashboard'))
        expect(File).to have_received(:write).with(output_path, include(Date.today.to_s))
      end
    end
  end
end
