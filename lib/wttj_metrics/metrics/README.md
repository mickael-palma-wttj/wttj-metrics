# Metrics

This directory contains the core calculation engines for all metrics tracked in the application. Each calculator is responsible for computing specific metrics from Linear or GitHub data.

## Architecture

All metric calculators inherit from `Base` and follow a consistent pattern:
1. Accept data (issues, PRs) and configuration in the initializer
2. Provide a `calculate` or `to_rows` method that returns structured metric data
3. Use helpers for common operations (date formatting, filtering, etc.)

## Calculators

### Base

Abstract base class providing common functionality for all metric calculators.

**Features:**
- Shared helper methods for date and issue manipulation
- Consistent interface for all calculators
- Common initialization pattern

### GitHub Metrics

Calculators for GitHub pull request data. See [metrics/github/README.md](github/README.md) for details.

### Linear Metrics

Calculators for Linear issue data. See [metrics/linear/README.md](linear/README.md) for details.

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
