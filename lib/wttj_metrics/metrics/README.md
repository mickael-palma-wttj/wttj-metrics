# Metrics

This directory contains the core calculation engines for all metrics tracked in the application. Each calculator is responsible for computing specific metrics from Linear issue data.

## Architecture

All metric calculators inherit from `Base` and follow a consistent pattern:
1. Accept issues and configuration in the initializer
2. Provide a `calculate` method that returns structured metric data
3. Use helpers for common operations (date formatting, issue filtering, etc.)

## Calculators

### Base

Abstract base class providing common functionality for all metric calculators.

**Features:**
- Shared helper methods for date and issue manipulation
- Consistent interface for all calculators
- Common initialization pattern

### BugCalculator

Calculates bug-related metrics including status distribution, resolution rates, and Mean Time To Resolution (MTTR).

**Metrics Calculated:**
- **Bug Status**: Count of bugs by status (Open, In Progress, Completed, Cancelled)
- **Bug Priority**: Distribution of bugs by priority level
- **MTTR (Mean Time To Resolution)**: Average time to resolve bugs (in hours)
- **Resolution Rate**: Percentage of bugs resolved vs total bugs
- **Bug Flow**: Weekly trends of opened, closed, and net change in bugs

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::BugCalculator.new(issues, workflow_states)
results = calculator.calculate

# Access metrics
puts results[:bug_status]        # { open: 10, in_progress: 5, completed: 100 }
puts results[:mttr]              # 48 (hours)
puts results[:resolution_rate]   # 85 (%)
```

### CycleCalculator

Calculates cycle-time metrics including scope changes, completion rates, and time-to-completion.

**Metrics Calculated:**
- **Scope Change Rate**: Percentage of issues added after cycle start
- **Completion Rate**: Percentage of issues completed in the cycle
- **Time to Completion**: Average days to complete issues
- **Cycle Velocity**: Number of issues completed per cycle
- **Progress**: Current completion percentage for active cycles

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::CycleCalculator.new(cycles, issues)
results = calculator.calculate

# Access cycle metrics
results.each do |cycle_data|
  puts "#{cycle_data[:name]}: #{cycle_data[:completion_rate]}% complete"
end
```

### DistributionCalculator

Calculates distribution of issues across various dimensions (teams, priorities, types).

**Metrics Calculated:**
- **Team Distribution**: Issues per team
- **Priority Distribution**: Issues by priority level
- **Type Distribution**: Issues by type (feature, bug, task, etc.)
- **Status Distribution**: Issues by current status

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::DistributionCalculator.new(issues)
results = calculator.calculate

puts results[:by_team]      # { "ATS" => 150, "Global ATS" => 200 }
puts results[:by_priority]  # { "High" => 50, "Medium" => 100, "Low" => 200 }
```

### FlowCalculator

Calculates flow metrics including throughput, work in progress, and cycle time trends.

**Metrics Calculated:**
- **Throughput**: Issues completed per week
- **Work in Progress (WIP)**: Current number of active issues
- **Cycle Time**: Average time from start to completion
- **Lead Time**: Average time from creation to completion
- **Flow Efficiency**: Ratio of active work time to total time

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::FlowCalculator.new(issues, start_date, end_date)
results = calculator.calculate

puts results[:throughput]      # { "2024-W49" => 25, "2024-W50" => 30 }
puts results[:avg_cycle_time]  # 5.2 (days)
puts results[:wip]             # 45 (issues)
```

### TeamCalculator

Calculates team-specific metrics including velocity, quality, and efficiency.

**Metrics Calculated:**
- **Team Velocity**: Issues completed per week by team
- **Bug Rate**: Percentage of bugs vs total issues by team
- **Completion Rate**: Percentage of issues completed on time
- **Average Cycle Time**: Mean time to complete issues
- **Team Capacity**: Total number of issues handled

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::TeamCalculator.new(issues, cycles)
results = calculator.calculate

results[:teams].each do |team, metrics|
  puts "#{team}: Velocity=#{metrics[:velocity]}, Bugs=#{metrics[:bug_rate]}%"
end
```

### TeamStatsCalculator

Calculates detailed statistics for team performance comparison and trending.

**Metrics Calculated:**
- **Completion Statistics**: Mean, median, and distribution of completion rates
- **Velocity Trends**: Weekly velocity patterns and trends
- **Quality Metrics**: Bug rates and resolution efficiency
- **Capacity Utilization**: Percentage of planned work completed

**Usage:**
```ruby
calculator = WttjMetrics::Metrics::TeamStatsCalculator.new(issues, cycles, teams)
results = calculator.calculate

results[:team_stats].each do |team, stats|
  puts "#{team}: Avg Completion=#{stats[:avg_completion]}%"
end
```

### TimeseriesCollector

Collects and aggregates time-series data for charts and trend analysis.

**Features:**
- Aggregates metrics by week, month, or custom periods
- Handles missing data points with interpolation
- Supports multiple metric types (count, average, sum)
- Formats data for Chart.js consumption

**Usage:**
```ruby
collector = WttjMetrics::Metrics::TimeseriesCollector.new(issues)
data = collector.collect(:created_at, period: :week)

# Returns data in Chart.js format
# {
#   labels: ["2024-W49", "2024-W50", "2024-W51"],
#   datasets: [{ data: [10, 15, 12] }]
# }
```

## Data Flow

```
Linear API Data
      ↓
[MetricsCalculator] ← orchestrates all calculators
      ↓
┌─────┴─────┬─────────┬──────────┬─────────┬──────────┐
↓           ↓         ↓          ↓         ↓          ↓
Bug      Cycle    Distribution Flow     Team    TeamStats
Calculator Calculator Calculator Calculator Calculator Calculator
      ↓
Structured Metric Data
      ↓
[Presenters] ← format for display
      ↓
HTML Report / CSV Export
```

## Design Principles

1. **Separation of Concerns**: Each calculator focuses on one metric domain
2. **Immutability**: Calculators don't modify input data
3. **Testability**: Pure functions with predictable outputs
4. **Performance**: Efficient data processing with minimal iterations
5. **Extensibility**: Easy to add new calculators following the Base pattern

## Common Patterns

### Calculator Structure
```ruby
class MyCalculator < Base
  def initialize(data, config = {})
    super()
    @data = data
    @config = config
  end

  def calculate
    # Return structured hash with metrics
    {
      metric_name: calculate_metric,
      another_metric: calculate_another
    }
  end

  private

  def calculate_metric
    # Implementation
  end
end
```

### Error Handling
All calculators handle edge cases:
- Empty data sets return zero or default values
- Invalid dates are skipped
- Missing fields are treated as nil

## Testing

Each calculator has comprehensive test coverage in `spec/wttj_metrics/metrics/`:
- Unit tests for each metric calculation
- Edge case testing (empty data, invalid dates, etc.)
- Integration tests with real-world data scenarios

Run tests with:
```bash
bundle exec rspec spec/wttj_metrics/metrics/
```

## Performance Considerations

- Calculators are designed to process thousands of issues efficiently
- Use memoization for expensive calculations
- Batch process data when possible
- Avoid N+1 queries by pre-loading related data
