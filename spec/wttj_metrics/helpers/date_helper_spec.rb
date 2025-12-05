# frozen_string_literal: true

RSpec.describe WttjMetrics::Helpers::DateHelper do
  subject(:helper) { test_class.new }

  let(:test_class) do
    Class.new do
      include WttjMetrics::Helpers::DateHelper
    end
  end

  describe '#parse_date' do
    it 'parses a valid date string' do
      expect(helper.parse_date('2024-12-05')).to eq(Date.new(2024, 12, 5))
    end

    it 'returns nil for nil input' do
      expect(helper.parse_date(nil)).to be_nil
    end
  end

  describe '#parse_datetime' do
    it 'parses a valid datetime string' do
      result = helper.parse_datetime('2024-12-05T10:30:00Z')
      expect(result).to be_a(DateTime)
      expect(result.hour).to eq(10)
    end

    it 'returns nil for nil input' do
      expect(helper.parse_datetime(nil)).to be_nil
    end
  end

  describe '#monday_of_week' do
    it 'returns the same date for a Monday' do
      monday = Date.new(2024, 12, 2) # Monday
      expect(helper.monday_of_week(monday)).to eq(monday)
    end

    it 'returns previous Monday for other days' do
      friday = Date.new(2024, 12, 6) # Friday
      expect(helper.monday_of_week(friday)).to eq(Date.new(2024, 12, 2))
    end

    it 'handles Sunday correctly' do
      sunday = Date.new(2024, 12, 8) # Sunday
      expect(helper.monday_of_week(sunday)).to eq(Date.new(2024, 12, 2))
    end

    it 'accepts string dates' do
      expect(helper.monday_of_week('2024-12-06')).to eq(Date.new(2024, 12, 2))
    end
  end

  describe '#format_week_label' do
    it 'formats as abbreviated month and day' do
      expect(helper.format_week_label('2024-12-06')).to eq('Dec 02')
    end
  end

  describe '#days_ago' do
    it 'calculates date N days ago' do
      result = helper.days_ago(7, from: Date.new(2024, 12, 10))
      expect(result).to eq('2024-12-03')
    end
  end

  describe '#days_between' do
    it 'calculates days between two dates' do
      expect(helper.days_between('2024-12-01', '2024-12-10')).to eq(9)
    end

    it 'returns nil if start_date is nil' do
      expect(helper.days_between(nil, '2024-12-10')).to be_nil
    end

    it 'returns nil if end_date is nil' do
      expect(helper.days_between('2024-12-01', nil)).to be_nil
    end

    it 'accepts Date objects' do
      start_date = Date.new(2024, 12, 1)
      end_date = Date.new(2024, 12, 10)
      expect(helper.days_between(start_date, end_date)).to eq(9)
    end
  end

  describe '#hours_between' do
    it 'calculates hours between two datetimes' do
      start_time = '2024-12-05T10:00:00Z'
      end_time = '2024-12-05T14:00:00Z'
      expect(helper.hours_between(start_time, end_time)).to eq(4.0)
    end

    it 'returns nil if start_time is nil' do
      expect(helper.hours_between(nil, '2024-12-05T14:00:00Z')).to be_nil
    end
  end
end
